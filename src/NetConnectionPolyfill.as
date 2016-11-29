package {
    import flash.display.Sprite;
    import flash.system.Security;
    import flash.net.NetConnection;
    import flash.external.ExternalInterface;
    import flash.events.Event;
    import flash.events.AsyncErrorEvent
    import flash.events.NetStatusEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.IOErrorEvent

    public class NetConnectionPolyfill extends Sprite {
        public const VERSION:String = CONFIG::version;
        
        private var _nc:NetConnection;

        private var _jsLogProxyName: String = "NetConnection.onFlashLog";
        private var _jsReadyProxyName: String = "NetConnection.onReady";
        private var _jsAsyncErrorEventProxyName: String = "NetConnection.onAsyncErrorEvent";
        private var _jsIOErrorEventProxyName: String = "NetConnection.onIOErrorEvent";
        private var _jsNetStatusEventProxyName: String = "NetConnection.onNetStatusEvent";
        private var _jsSecurityErrorEventProxyName: String = "NetConnection.onSecurityErrorEvent";
        private var _jsClientCallProxyName: String = "NetConnection.onClientCall";
    

        public function NetConnectionPolyfill() {
            log('info', 'New NetConnection instance');
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        private function init():void {
            Security.allowDomain("*");
            Security.allowInsecureDomain("*");

            if(ExternalInterface.available) {
                registerExternalMethods();
            }

            _nc = new NetConnection();

            _nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
            _nc.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorEvent);
            _nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorEvent);
            _nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAyncErrorEvent);

            callExternalInterface(_jsReadyProxyName);
        }

        private function registerExternalMethods():void {
            try {
                ExternalInterface.addCallback("nc_addHeader", onAddHeaderCalled);
                ExternalInterface.addCallback("nc_call", onCallCalled);
                ExternalInterface.addCallback("nc_close", onCloseCalled);
                ExternalInterface.addCallback("nc_connect", onConnectCalled);

                ExternalInterface.addCallback("nc_getProperty", onGetPropertyCalled);
                ExternalInterface.addCallback("nc_setProperty", onSetPropertyCalled);
                ExternalInterface.addCallback("nc_setClient", onSetClientCalled);

            } catch (e:Error) {
                log("error", e.message);
            } finally {}
        }

        private function onAddedToStage(event: Event):void {
            init();
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAyncErrorEvent(event: AsyncErrorEvent): void {
            callExternalInterface(_jsAsyncErrorEventProxyName, event.type, event.error);
        }

        private function onIOErrorEvent(event:IOErrorEvent): void {
            callExternalInterface(_jsIOErrorEventProxyName, event.type, event.text);
        }

        private function onSecurityErrorEvent(event: SecurityErrorEvent): void {
            callExternalInterface(_jsSecurityErrorEventProxyName, event.type, event.text);
        }

        private function onNetStatusEvent(event: NetStatusEvent): void {
            callExternalInterface(_jsNetStatusEventProxyName, event.type, event.info);
        }

        private function onAddHeaderCalled(opeartion: String, mustUnderstand: Boolean = false, param: Object = null):void {
            this._nc.addHeader(opeartion, mustUnderstand, param);
        }

        private function onCallCalled(command: String, ... args):void {
            try {
                log('info', 'Calling '+command);
                var __incomingArgs:* = args as Array;
                var __newArgs:Array = [command, null].concat(__incomingArgs);
                var __sanitizedArgs:Array = cleanObject(__newArgs);
                this._nc.call.apply(this._nc, __sanitizedArgs);
            } catch (e: Error) {
                log('error', e.message);
            }
        }

        private function onCloseCalled():void {
            this._nc.close();
        }

        private function onConnectCalled(command:*, ...args):void {
            log('info', 'Connecting to '+command);
            var __incomingArgs:* = args as Array;
            var __newArgs:Array = [command].concat(__incomingArgs);
            var __sanitizedArgs:Array = cleanObject(__newArgs);
            this._nc.connect.apply(this._nc, __sanitizedArgs);
        }

        private function onSetClientCalled(methods: Array):void {
            this._nc.client = new Object();
            try {
                for (var i = 0; i < methods.length; i++) {
                    var method = methods[i];
                    this._nc.client[method] = function(... args) {
                        callExternalInterface(_jsClientCallProxyName, method, args);
                    }
                }
            } catch (e: Error) {
                log('error', e.message);
            }
        }

        private function onGetPropertyCalled(pPropertyName:String = ""):* {
            if (this._nc.hasOwnProperty(pPropertyName)) {
                if (this._nc[pPropertyName] is Function) {
                    log('warning', 'It is not possible to get a function as a property');
                    return null;
                }
                return this._nc[pPropertyName];
            }
            return null;
        }

        private function onSetPropertyCalled(pPropertyName: String, value: *):void {
            switch(pPropertyName) {
                case "objectEncoding":
                    this._nc.objectEncoding = value as uint;
                    break;
                case "proxyType":
                    this._nc.proxyType = value as String;
                    break;
                case "maxPeerConnections":
                    this._nc.maxPeerConnections = value as uint;
                    break;
                default:
                    log('warning', 'Property '+pPropertyName+ ' cannot be set.');
            }
        }

        private function log(level: String, message: *):void {
            if (loaderInfo.parameters.debug != undefined && loaderInfo.parameters.debug == "true") {
                this.callExternalInterface(_jsLogProxyName, level, cleanObject(message));
            }
        }

        private function callExternalInterface(proxyName: String, ...args):void {
            if (ExternalInterface.available) {
                var __incomingArgs:* = args as Array;
                var __newArgs:Array = [proxyName, ExternalInterface.objectID].concat(__incomingArgs);
                var __sanitizedArgs:Array = cleanObject(__newArgs);
                ExternalInterface.call.apply(null, __sanitizedArgs);
            }
        }

        private function cleanObject(o:*):* {
            if (o == null) {
                return null;
            }
            if (o is String) {
                return o.split("\\").join("\\\\");
            } else if (o is Array) {
                var __sanitizedArray:Array = new Array();

                for each (var __item in o){
                    __sanitizedArray.push(cleanObject(__item));
                }

                return __sanitizedArray;
            } else if (typeof(o) == 'object') {
                var __sanitizedObject:Object = new Object();

                for (var __i in o){
                    __sanitizedObject[__i] = cleanObject(o[__i]);
                }

                return __sanitizedObject;
            } else {
                return o;
            }
        }
    }
}