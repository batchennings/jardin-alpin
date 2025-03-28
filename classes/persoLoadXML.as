﻿package
{
	import flash.display.*
	import flash.net.*;
	import flash.events.*;
	import flash.system.*
	import flash.events.Event;
	import flash.display.Sprite

	public class persoLoadXML extends EventDispatcher
	{
		public var chargeur:URLLoader;

		public function persoLoadXML (pURL:String)
		{
			chargeur = new URLLoader();// objet de chargement

			var fichier:URLRequest = new URLRequest(pURL);// url du fichier chargé

			chargeur.addEventListener( Event.COMPLETE, chargementComplet );
			chargeur.load( fichier );
		}
		private function chargementComplet (e:Event):void
		{
			dispatchEvent(new Event("XML_COMPLETE"))
		}
	}
}

