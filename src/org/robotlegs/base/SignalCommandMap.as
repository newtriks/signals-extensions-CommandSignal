package org.robotlegs.base {
import flash.utils.Dictionary;
import flash.utils.describeType;

import net.richardlord.signals.SignalBase;

import org.robotlegs.core.IInjector;
import org.robotlegs.core.ISignalCommandMap;

public class SignalCommandMap implements ISignalCommandMap {
    protected var injector:IInjector;
    protected var signalMap:Dictionary;
    protected var signalClassMap:Dictionary;
    protected var verifiedCommandClasses:Dictionary;
    protected var detainedCommands:Dictionary;

    public function SignalCommandMap(injector:IInjector) {
        this.injector = injector;
        signalMap = new Dictionary(false);
        signalClassMap = new Dictionary(false);
        verifiedCommandClasses = new Dictionary(false);
        detainedCommands = new Dictionary(false);
    }

    public function mapSignal(signal:SignalBase, commandClass:Class, oneShot:Boolean = false):void {
        verifyCommandClass(commandClass);
        if (hasSignalCommand(signal, commandClass))
            return;
        const signalCommandMap:Dictionary = signalMap[signal] ||= new Dictionary(false);
        const callback:Function = function ():void {
            routeSignalToCommand(signal, arguments, commandClass, oneShot);
        };

        signalCommandMap[commandClass] = callback;
        signal.add(callback);
    }

    public function mapSignalClass(signalClass:Class, commandClass:Class, oneShot:Boolean = false):SignalBase {
        var signal:SignalBase = getSignalClassInstance(signalClass);
        mapSignal(signal, commandClass, oneShot);
        return signal;
    }

    protected function getSignalClassInstance(signalClass:Class):SignalBase {
        return SignalBase(signalClassMap[signalClass]) || createSignalClassInstance(signalClass);
    }

    private function createSignalClassInstance(signalClass:Class):SignalBase {
        var injectorForSignalInstance:IInjector = injector;
        var signal:SignalBase;
        if (injector.hasMapping(IInjector))
            injectorForSignalInstance = injector.getInstance(IInjector);
        signal = injectorForSignalInstance.instantiate(signalClass);
        injectorForSignalInstance.mapValue(signalClass, signal);
        signalClassMap[signalClass] = signal;
        return signal;
    }

    public function hasSignalCommand(signal:SignalBase, commandClass:Class):Boolean {
        var callbacksByCommandClass:Dictionary = signalMap[signal];
        if (callbacksByCommandClass == null) return false;
        var callback:Function = callbacksByCommandClass[commandClass];
        return callback != null;
    }

    public function unmapSignal(signal:SignalBase, commandClass:Class):void {
        var callbacksByCommandClass:Dictionary = signalMap[signal];
        if (callbacksByCommandClass == null) return;
        var callback:Function = callbacksByCommandClass[commandClass];
        if (callback == null) return;
        signal.remove(callback);
        delete callbacksByCommandClass[commandClass];
    }

    public function unmapSignalClass(signalClass:Class, commandClass:Class):void {
        unmapSignal(getSignalClassInstance(signalClass), commandClass);
    }

    protected function routeSignalToCommand(signal:SignalBase, valueObjects:Array, commandClass:Class, oneshot:Boolean):void {
        mapSignalValues(signal.types, valueObjects);
        createCommandInstance(commandClass).execute();
        unmapSignalValues(signal.types, valueObjects);
        if (oneshot)
            unmapSignal(signal, commandClass);
    }

    protected function createCommandInstance(commandClass:Class):Object {
        return injector.instantiate(commandClass);
    }

    protected function mapSignalValues(valueClasses:Array, valueObjects:Array):void {
        for (var i:uint = 0; i < valueClasses.length; i++) {
            injector.mapValue(valueClasses[i], valueObjects[i]);
        }
    }

    protected function unmapSignalValues(valueClasses:Array, valueObjects:Array):void {
        for (var i:uint = 0; i < valueClasses.length; i++) {
            injector.unmap(valueClasses[i]);
        }
    }

    protected function verifyCommandClass(commandClass:Class):void {
        if (verifiedCommandClasses[commandClass]) return;
        if (describeType(commandClass).factory.method.(@name == "execute").length() != 1) {
            throw new ContextError(ContextError.E_COMMANDMAP_NOIMPL + ' - ' + commandClass);
        }
        verifiedCommandClasses[commandClass] = true;
    }

    public function detain(command:Object):void {
        detainedCommands[command] = true;
    }

    public function release(command:Object):void {
        if (detainedCommands[command])
            delete detainedCommands[command];
    }
}
}
