package
{
	import flash.display.Sprite;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.events.ProgressEvent;
	import flash.events.*;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.display.DisplayObject;

	dynamic public class persoLoadFile extends Sprite
	{
		static var urlImage:URLRequest;
		public var chargeur:Loader;
		public var _pourcentage:Number;

		public function persoLoadFile(nomImage:String):void
		{

			chargeur=new Loader();
			configurerEcouteurs(chargeur.contentLoaderInfo);
			urlImage=new URLRequest(nomImage);
			chargeur.load(urlImage);

			addChild(chargeur);
			trace("Class persoLoadFile : objet chargeur créé");
		}
		private function configurerEcouteurs(dispatcheur:IEventDispatcher):void
		{
			dispatcheur.addEventListener(Event.OPEN, DebutChargement);
			dispatcheur.addEventListener(ProgressEvent.PROGRESS,ProgressionChargement);
			dispatcheur.addEventListener(Event.COMPLETE,FinChargement);
			dispatcheur.addEventListener(IOErrorEvent.IO_ERROR,ErreurChargement);
		}
		private function DebutChargement(evt:Event):void
		{
			trace("Class persoLoadFile : début du chargement");
		}
		private function ProgressionChargement(evt:ProgressEvent):void
		{
			_pourcentage = evt.bytesLoaded/evt.bytesTotal*100;
			dispatchEvent(new Event("progress"));
		}

		public function FinChargement(evt:Event):void
		{
			chargeur.removeEventListener(ProgressEvent.PROGRESS,ProgressionChargement);
			chargeur.removeEventListener(Event.COMPLETE,FinChargement);
			dispatchEvent(new Event("loaded"));
			trace("Class persoLoadFile : chargement terminé");
		}
		public function ErreurChargement(evt:IOErrorEvent):void
		{
			chargeur.removeEventListener(IOErrorEvent.IO_ERROR,ProgressionChargement);
			trace("Class persoLoadFile : erreur ->"+evt)
		}

		// récupérer le pourcentage du chargement
		public function get pc():Number
		{
			return _pourcentage;
		}
	}
}
