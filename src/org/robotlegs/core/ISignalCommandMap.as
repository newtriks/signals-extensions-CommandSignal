package org.robotlegs.core {
import net.richardlord.signals.SignalBase;

public interface ISignalCommandMap {
    function mapSignal(signal:SignalBase, commandClass:Class, oneShot:Boolean = false):void;

    function mapSignalClass(signalClass:Class, commandClass:Class, oneShot:Boolean = false):SignalBase;

    function hasSignalCommand(signal:SignalBase, commandClass:Class):Boolean;

    function unmapSignal(signal:SignalBase, commandClass:Class):void;

    function unmapSignalClass(signalClass:Class, commandClass:Class):void;

    function detain(command:Object):void;

    function release(command:Object):void;
}
}
