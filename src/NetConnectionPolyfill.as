package {
    import flash.display.Sprite;
    import flash.system.Security;
    import flash.net.NetConnection;
    import flash.external.ExternalInterface;
    import flash.events.Event;

    public class NetConnectionPolyfill extends Sprite {
        public const VERSION:String = CONFIG::version;
        private var _nc:NetConnection;

        public function NetConnectionPolyfill() {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        private function init():void {
            Security.allowDomain("*");
            Security.allowInsecureDomain("*");

            if(ExternalInterface.available) {
                registerExternalMethods();
            }

            _nc = new NetConnection();
        }

        private function registerExternalMethods():void {
            try {

            } catch (e:Error) {
                
            } finally {}
        }

        private function onAddedToStage(event: Event):void {
            init();
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
    }
}