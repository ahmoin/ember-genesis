--!nocheck

local freeRunnerThread = nil :: thread?

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)

	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Connection)
end

function Connection:Disconnect()
	self._connected = false

	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

setmetatable(Connection, {
	__index = function(_, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_handlerListHead = false,
	}, Signal) :: any
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection
end

function Signal:DisconnectAll()
	self._handlerListHead = false
end

function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				if type(freeRunnerThread) == "thread" then
					coroutine.resume(freeRunnerThread)
				end
			end
			if type(freeRunnerThread) == "thread" then
				task.spawn(freeRunnerThread, item._fn, ...)
			end
		end
		item = item._next
	end
end

function Signal:Once(fn)
	local cn
	cn = self:Connect(function(...)
		if cn._connected then
			cn:Disconnect()
		end
		fn(...)
	end)
	return cn
end

setmetatable(Signal, {
	__index = function(_, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

return Signal
