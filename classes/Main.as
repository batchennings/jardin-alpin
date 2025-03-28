﻿package
{
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.LineScaleMode;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.DisplayObject;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;

    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.display.StageAlign;

    import flash.events.MouseEvent;
    import flash.events.Event;

    import flash.text.TextFieldAutoSize;

    import flash.filters.*;

    import aze.motion.easing.*;
    import aze.motion.eaze;

    import persoLoadFile;
    import persoLoadXML;
    import Scrollbar;

    public class Main extends Sprite
    {
        private var jardinBox:Sprite;							// DiplayObject qui contient le jardin (swf chargé)
        private var planBox:Sprite;								// DiplayObject qui contient le plan du jardin (swf chargé)
        private var swfJardin:Object;							// Le jardin swf chargé.
        private var swfPlan:Object;								// Le plan swf chargé.
        private var xmlDatas:XML;								// Les données XML
        private var xmlDir:String;								// Le dossier du fichier XML
        private var imageDir:String;							// Le dossier des images à charger dans les fiches
        private var swfDir:String;								// Le dossier des swfs chargés
        private var sceneOrigine:Array; 						// position où vient se coller le swf/panoramique.
        private var surfaceUtile:Array; 						// surface sur laquelle s'affiche la panoramique.
        private var ficheActive:MovieClip						// la fiche active
            private var panoIndic:int;								// indicateur de position dans la panoramique
        private var panoFlagsArray:Array;						// tableau contenant les positions auxquelles doit bouger la panoramique, en fonction de meut positionnement dans le swf cible (le jardin)
        private var panoWidth:int;								// largeur de la panoramique chargée
        private var sceneSize:Array;							// taille de la scène (le .fla quoi)
        private var ficheLabel:MovieClip;						// movieclip qui s'affiche au survol sur un hotspot

        private var panoState:String;							// Etat de la panoramaique - en butée à droite, à gauche, ou "mobile" (pas en butée)

        private var idJardin:int;								// id du jardin actif
        private var idPano:int;									// id de la panoramique active

        private var mainBox:Object;    							// Clip principal — le centre des opérations graphiques

        public function Main():void
        {
            xmlDir = "datas/";
            imageDir = "images/";
            swfDir = "";

            var xmlDirFlashvar = this.loaderInfo.parameters.xmlDir;
            var imageDirFlashvar = this.loaderInfo.parameters.imageDir;
            var swfDirFlashvar = this.loaderInfo.parameters.swfDir;

            if (xmlDirFlashvar != undefined) xmlDir = xmlDirFlashvar;
            if (imageDirFlashvar != undefined) imageDir = imageDirFlashvar;
            if (swfDirFlashvar != undefined) swfDir = swfDirFlashvar;

            sceneOrigine = new Array(12, 13);
            surfaceUtile = new Array(1000, 560);
            sceneSize = new Array(1020, 650)

                mainBox = mainBox_mc;

            idJardin = 0;
            idPano = 0;

            manageScreen();
            chargementXML();
        }

        //		   __    ___   _ __    __      ___
        //		 /'__`\ /'___\/\`'__\/'__`\  /' _ `\
        //		/\  __//\ \__/\ \ \//\ \L\.\_/\ \/\ \
        //		\ \____\ \____\\ \_\\ \__/.\_\ \_\ \_\
        //		 \/____/\/____/ \/_/ \/__/\/_/\/_/\/_/


        private function manageScreen():void
        {
            //stage.scaleMode = StageScaleMode.NO_SCALE
            stage.align = StageAlign.TOP_LEFT;

            stage.addEventListener(Event.RESIZE, resizeHandler)

                mainBox.fullscreen_mc.buttonMode = true;
            mainBox.fullscreen_mc.addEventListener(MouseEvent.MOUSE_DOWN, toggleFullScreen);

            mainBox.fullscreen_mc.fsReduction_mc.alpha = 0;
        }
        private function resizeHandler(e:Event):void
        {
            //			mainBox.x = (stage.stageWidth/2)-(mainBox.width/2)
            //			mainBox.y = (stage.stageHeight/2)-(mainBox.height/2)
        }
        private function toggleFullScreen(e:MouseEvent):void
        {
            switch (stage.displayState) {
                case "normal" :
                    stage.displayState="fullScreen";

                    eaze(mainBox.fullscreen_mc.fsReduction_mc).to(.5,{alpha:1});
                    eaze(mainBox.fullscreen_mc.fsPleinEcran_mc).to(.5,{alpha:0});

                    //					var _w:Number = stage.stageWidth
                    //					var _ratio:Number = _w/sceneSize[0]
                    //					mainBox.scaleX = mainBox.scaleY = _ratio
                    break;
                case "fullScreen" :
                default :
                    stage.displayState="normal";

                    eaze(mainBox.fullscreen_mc.fsReduction_mc).to(.5,{alpha:0});
                    eaze(mainBox.fullscreen_mc.fsPleinEcran_mc).to(.5,{alpha:1});

                    //mainBox.scaleX = mainBox.scaleY = 1
                    break;
            }
        }


        //						  ___
        //						 /\_ \
        //		 __  _   ___ ___ \//\ \
        //		/\ \/'\/' __` __`\ \ \ \
        //		\/>  <//\ \/\ \/\ \ \_\ \_
        //		 /\_/\_\ \_\ \_\ \_\/\____\
        //		 \//\/_/\/_/\/_/\/_/\/____/
        //		--
        //      ASCII w/ Larry 3D

        private function chargementXML():void
        {
            var _xl:persoLoadXML = new persoLoadXML(xmlDir+"datas.xml")
                _xl.addEventListener("XML_COMPLETE", chargementXML_complete)
        }
        private function chargementXML_complete(e:Event):void
        {
            xmlDatas = new XML(e.target.chargeur.data)
                loadJardin(swfDir+xmlDatas.jardin[idJardin].pano[idPano].pano_dir);
            loadPlan(swfDir+xmlDatas.jardin[idJardin].jardin_plan);

            mainBox.nomJardin_mc.nom_jardin_txt.text = xmlDatas.jardin[idJardin].jardin_nom.toUpperCase()
        }
        //												   __                                                               __
        //						__                        /\ \                                                             /\ \__
        //		   __      ___ /\_\    ___ ___         ___\ \ \___      __     _ __    __      __    ___ ___      __    ___\ \ ,_\
        //		 /'__`\  /' _ `\/\ \ /' __` __`\      /'___\ \  _ `\  /'__`\  /\`'__\/'_ `\  /'__`\/' __` __`\  /'__`\/' _ `\ \ \/
        //		/\ \L\.\_/\ \/\ \ \ \/\ \/\ \/\ \    /\ \__/\ \ \ \ \/\ \L\.\_\ \ \//\ \L\ \/\  __//\ \/\ \/\ \/\  __//\ \/\ \ \ \_
        //		\ \__/.\_\ \_\ \_\ \_\ \_\ \_\ \_\   \ \____\\ \_\ \_\ \__/.\_\\ \_\\ \____ \ \____\ \_\ \_\ \_\ \____\ \_\ \_\ \__\
        //		 \/__/\/_/\/_/\/_/\/_/\/_/\/_/\/_/    \/____/ \/_/\/_/\/__/\/_/ \/_/ \/___L\ \/____/\/_/\/_/\/_/\/____/\/_/\/_/\/__/
        //																			   /\____/
        //																			   \_/__/


        private function displayLoadAnimation(xAnim:int, yAnim:int):void
        {
            var _sl:MovieClip = new loadAnimation();

            _sl.name = "loader"+xAnim
                _sl.x = xAnim
                _sl.y = yAnim

                _sl.alpha = 0

                mainBox.addChild(_sl)

                eaze(_sl).delay(.5).to(.5,{alpha:1})
        }
        private function deleteLoadAnimation(xAnim:int):void
        {
            // alors là attention, c'est bricolage.
            // le paramètre qui est ici passé est le même qui est passé à l'appel de l'animation (displayLoadAnimation)
            // vu que sa position en x nous a permis de le nommer, il nous faut à nouveau cette position pour l'identifier et le faire disparaitre >>> _sl.name = "loader"+xAnim dans displayLoadAnimation()

            var _sl:MovieClip = mainBox.getChildByName("loader"+xAnim) as MovieClip;
            eaze(_sl).to(.25, {alpha:0}).easing(Cubic.easeOut).onComplete(removeLoadAnimation, _sl)
        }
        private function removeLoadAnimation(obj:MovieClip):void
        {
            var _t:MovieClip = obj;
            mainBox.removeChild(_t);
        }
        //			  __                                                               __                                   __
        //			 /\ \                                                             /\ \__          __                   /\ \  __
        //		  ___\ \ \___      __     _ __    __      __    ___ ___      __    ___\ \ ,_\        /\_\     __     _ __  \_\ \/\_\    ___
        //		 /'___\ \  _ `\  /'__`\  /\`'__\/'_ `\  /'__`\/' __` __`\  /'__`\/' _ `\ \ \/        \/\ \  /'__`\  /\`'__\/'_` \/\ \ /' _ `\
        //		/\ \__/\ \ \ \ \/\ \L\.\_\ \ \//\ \L\ \/\  __//\ \/\ \/\ \/\  __//\ \/\ \ \ \_        \ \ \/\ \L\.\_\ \ \//\ \L\ \ \ \/\ \/\ \
        //		\ \____\\ \_\ \_\ \__/.\_\\ \_\\ \____ \ \____\ \_\ \_\ \_\ \____\ \_\ \_\ \__\       _\ \ \ \__/.\_\\ \_\\ \___,_\ \_\ \_\ \_\
        //		 \/____/ \/_/\/_/\/__/\/_/ \/_/ \/___L\ \/____/\/_/\/_/\/_/\/____/\/_/\/_/\/__/      /\ \_\ \/__/\/_/ \/_/ \/__,_ /\/_/\/_/\/_/
        //										  /\____/                                            \ \____/
        //										  \_/__/                                              \/___/

        private function loadJardin(fileDir:String, prevObj:Sprite = undefined):void
        {
            if(prevObj) mainBox.removeChild(prevObj);

            var _l:persoLoadFile = new persoLoadFile(fileDir);
            _l.addEventListener("progress", loadJardin_prog);
            _l.addEventListener("loaded", loadJardin_end);

            displayLoadAnimation(sceneSize[0]/2, (sceneSize[1]/2)-35 )
        }
        private function loadJardin_prog(e:Event):void
        {
            var _t:Object = e.target
                var _p:int = _t._pourcentage

                // trace("Chargement : "+_p+"%")
        }
        private function loadJardin_end(e:Event):void
        {
            displayJardin(e.target);
            deleteLoadAnimation(stage.stageWidth/2)
        }

        ////////////////////////////////////
        //////    AFFICHAGE DU JARDIN
        ///////////////////////////////////

        private function displayJardin(target:Object):void
        {
            var _t:persoLoadFile = target as persoLoadFile

                swfJardin = _t

                var _msk:Sprite = new Sprite();
            _msk.graphics.beginFill(0xFF0000);
            _msk.graphics.drawRect(sceneOrigine[0], sceneOrigine[1], surfaceUtile[0], surfaceUtile[1]);

            jardinBox = new Sprite();
            jardinBox.x = sceneOrigine[0]
                jardinBox.y = sceneOrigine[1]
                jardinBox.addChild(_t)

                mainBox.addChild(_msk);
            jardinBox.mask = _msk;
            mainBox.addChildAt(jardinBox,0)

                eaze(jardinBox).from(1, {alpha:0}).easing(Cubic.easeOut);

            panoIndic = 0;
            panoState = "BUTEE_GAUCHE"

                panoDivision();
            listHotspots();
            configureArrows();
        }

        //			  __                                                               __                                __
        //			 /\ \                                                             /\ \__                            /\ \__
        //		  ___\ \ \___      __     _ __    __      __    ___ ___      __    ___\ \ ,_\        ___     __     _ __\ \ ,_\    __
        //		 /'___\ \  _ `\  /'__`\  /\`'__\/'_ `\  /'__`\/' __` __`\  /'__`\/' _ `\ \ \/       /'___\ /'__`\  /\`'__\ \ \/  /'__`\
        //		/\ \__/\ \ \ \ \/\ \L\.\_\ \ \//\ \L\ \/\  __//\ \/\ \/\ \/\  __//\ \/\ \ \ \_     /\ \__//\ \L\.\_\ \ \/ \ \ \_/\  __/
        //		\ \____\\ \_\ \_\ \__/.\_\\ \_\\ \____ \ \____\ \_\ \_\ \_\ \____\ \_\ \_\ \__\    \ \____\ \__/.\_\\ \_\  \ \__\ \____\
        //		 \/____/ \/_/\/_/\/__/\/_/ \/_/ \/___L\ \/____/\/_/\/_/\/_/\/____/\/_/\/_/\/__/     \/____/\/__/\/_/ \/_/   \/__/\/____/
        //										  /\____/
        //										  \_/__/
        //		  __                          __                      __
        //		 /\ \                      __/\ \__                  /\ \__  __
        //		 \_\ \     __         ____/\_\ \ ,_\  __  __     __  \ \ ,_\/\_\    ___     ___
        //		 /'_` \  /'__`\      /',__\/\ \ \ \/ /\ \/\ \  /'__`\ \ \ \/\/\ \  / __`\ /' _ `\
        //		/\ \L\ \/\  __/     /\__, `\ \ \ \ \_\ \ \_\ \/\ \L\.\_\ \ \_\ \ \/\ \L\ \/\ \/\ \
        //		\ \___,_\ \____\    \/\____/\ \_\ \__\\ \____/\ \__/.\_\\ \__\\ \_\ \____/\ \_\ \_\
        //		 \/__,_ /\/____/     \/___/  \/_/\/__/ \/___/  \/__/\/_/ \/__/ \/_/\/___/  \/_/\/_/



        private function loadPlan(fileDir:String):void
        {
            var _l:persoLoadFile = new persoLoadFile(fileDir);
            _l.addEventListener("progress", loadPlan_prog);
            _l.addEventListener("loaded", loadPlan_end);

            displayLoadAnimation(1000, 625);
        }
        private function loadPlan_prog(e:Event):void
        {
            var _t:Object = e.target
                var _p:int = _t._pourcentage

                // trace("Chargement : "+_p+"%")
        }
        private function loadPlan_end(e:Event):void
        {
            displayPlan(e.target);
            deleteLoadAnimation(1000)
        }

        ////////////////////////////////////
        //////  AFFICHAGE DE LA CARTE
        ///////////////////////////////////

        private function displayPlan(target:Object):void
        {
            var _t:persoLoadFile = target as persoLoadFile

                swfPlan = _t

                planBox = new Sprite();
            planBox.x = 784
                planBox.y = 567

                planBox.addChild(_t)
                mainBox.addChild(planBox)

                eaze(_t).from(.5, {alpha:0});

            handlerPlan();
        }

        //							  __                                                                                       __
        //							 /\ \__  __                                    __                                         /\ \__
        //		   __      __    ____\ \ ,_\/\_\    ___     ___     ___      __   /\_\  _ __    __         ___     __     _ __\ \ ,_\    __
        //		 /'_ `\  /'__`\ /',__\\ \ \/\/\ \  / __`\ /' _ `\ /' _ `\  /'__`\ \/\ \/\`'__\/'__`\      /'___\ /'__`\  /\`'__\ \ \/  /'__`\
        //		/\ \L\ \/\  __//\__, `\\ \ \_\ \ \/\ \L\ \/\ \/\ \/\ \/\ \/\ \L\.\_\ \ \ \ \//\  __/     /\ \__//\ \L\.\_\ \ \/ \ \ \_/\  __/
        //		\ \____ \ \____\/\____/ \ \__\\ \_\ \____/\ \_\ \_\ \_\ \_\ \__/.\_\\ \_\ \_\\ \____\    \ \____\ \__/.\_\\ \_\  \ \__\ \____\
        //		 \/___L\ \/____/\/___/   \/__/ \/_/\/___/  \/_/\/_/\/_/\/_/\/__/\/_/ \/_/\/_/ \/____/     \/____/\/__/\/_/ \/_/   \/__/\/____/
        //		   /\____/
        //		   \_/__/



        private function handlerPlan():void
        {
            var _pswf:Object = swfPlan.chargeur.content

                for (var i:int = 1 ; i<_pswf.numChildren ; i++)
                {
                    var _p:MovieClip = _pswf.getChildAt(i) as MovieClip

                        eaze(_p).to(.5, {alpha:.75})

                        _p.buttonMode = true;
                    _p.addEventListener(MouseEvent.MOUSE_OVER, plan_MOUSE_OVER)
                        _p.addEventListener(MouseEvent.MOUSE_OUT, plan_MOUSE_OUT)
                        _p.addEventListener(MouseEvent.MOUSE_DOWN, plan_MOUSE_DOWN)
                }
            getActivePlanPano();
        }
        private function desactivePlan():void
        {
            var _pswf:Object = swfPlan.chargeur.content;

            for (var i:int = 1 ; i<_pswf.numChildren ; i++)
            {
                var _p:MovieClip = _pswf.getChildAt(i) as MovieClip
                    _p.removeEventListener(MouseEvent.MOUSE_OVER, plan_MOUSE_OVER)
                    _p.removeEventListener(MouseEvent.MOUSE_OUT, plan_MOUSE_OUT)
                    _p.removeEventListener(MouseEvent.MOUSE_DOWN, plan_MOUSE_DOWN)
            }
        }


        private function getActivePlanPano():void
        {
            var _pswf:Object = swfPlan.chargeur.content

                for (var i:int = 1 ; i<_pswf.numChildren ; i++)
                {
                    var _p:MovieClip = _pswf.getChildAt(i) as MovieClip

                        if(i == idPano+1)
                        {
                            eaze(_p).to(.5, {tint:0x9cf500});
                            _p.buttonMode = false;
                            _p.removeEventListener(MouseEvent.MOUSE_OVER, plan_MOUSE_OVER)
                                _p.removeEventListener(MouseEvent.MOUSE_OUT, plan_MOUSE_OUT)
                                _p.removeEventListener(MouseEvent.MOUSE_DOWN, plan_MOUSE_DOWN)
                        }
                        else
                        {
                            eaze(_p).to(1,{alpha:.75}).tint(0, 0);

                            if (!_p.hasEventListener(MouseEvent.MOUSE_OVER))
                            {
                                _p.buttonMode = true;
                                _p.addEventListener(MouseEvent.MOUSE_OVER, plan_MOUSE_OVER)
                                    _p.addEventListener(MouseEvent.MOUSE_OUT, plan_MOUSE_OUT)
                                    _p.addEventListener(MouseEvent.MOUSE_DOWN, plan_MOUSE_DOWN)
                            }
                        }
                }
        }
        private function plan_MOUSE_OVER(e:MouseEvent):void
        {
            var _t:MovieClip = e.currentTarget as MovieClip;
            eaze(_t).to(.15, {alpha:1})
        }
        private function plan_MOUSE_OUT(e:MouseEvent):void
        {
            var _t:MovieClip = e.currentTarget as MovieClip;
            eaze(_t).to(.15, {alpha:.75})
        }
        private function plan_MOUSE_DOWN(e:MouseEvent):void
        {
            var _t:MovieClip = e.currentTarget as MovieClip;

            var _pswf:Object = swfPlan.chargeur.content
                var _id:int = _pswf.getChildIndex(_t)-1

                removeJardin(_id);

            getActivePlanPano()
        }

        //							 __
        //							/\ \__  __
        //		  ____     __    ___\ \ ,_\/\_\    ___     ___     ____
        //		 /',__\  /'__`\ /'___\ \ \/\/\ \  / __`\ /' _ `\  /',__\
        //		/\__, `\/\  __//\ \__/\ \ \_\ \ \/\ \L\ \/\ \/\ \/\__, `\
        //		\/\____/\ \____\ \____\\ \__\\ \_\ \____/\ \_\ \_\/\____/
        //		 \/___/  \/____/\/____/ \/__/ \/_/\/___/  \/_/\/_/\/___/


        // division de la panoramique chargée ( en sections égales à la valeur de la variable _pas)
        // et stockage dans un tableau (panoFlagsArray).

        private function panoDivision():void
        {
            var _pas:int = 500 // pas de la panoramique

                panoFlagsArray = new Array();
            panoFlagsArray.push(0); // on commence à zéro

            var _jswf:Object = swfJardin.chargeur.content;
            panoWidth = _jswf.width; // largeur de la pano chargée

            var _nsx:Number = panoWidth/_pas // largeur/pas -> nombre de sections
                var _sx:Number = panoWidth/Math.floor(_nsx);

            var _vd:Number = ((panoWidth)-(_pas*Math.floor(_nsx)))/(Math.floor(_nsx)) // valeur à redistribuer
                var _npas = _pas+_vd // pas de la panoramique + valeur à redistribuer

                for(var i:int = 1; i<Math.floor(_nsx)-1 ; i++)
                {
                    var _v:int = _npas*i
                        panoFlagsArray.push(_v)
                }
        }
        //							  __                                                               __              __                           __
        //							 /\ \__  __                                    __                 /\ \            /\ \__                       /\ \__
        //		   __      __    ____\ \ ,_\/\_\    ___     ___     ___      __   /\_\  _ __    __    \ \ \___     ___\ \ ,_\   ____  _____     ___\ \ ,_\   ____
        //		 /'_ `\  /'__`\ /',__\\ \ \/\/\ \  / __`\ /' _ `\ /' _ `\  /'__`\ \/\ \/\`'__\/'__`\   \ \  _ `\  / __`\ \ \/  /',__\/\ '__`\  / __`\ \ \/  /',__\
        //		/\ \L\ \/\  __//\__, `\\ \ \_\ \ \/\ \L\ \/\ \/\ \/\ \/\ \/\ \L\.\_\ \ \ \ \//\  __/    \ \ \ \ \/\ \L\ \ \ \_/\__, `\ \ \L\ \/\ \L\ \ \ \_/\__, `\
        //		\ \____ \ \____\/\____/ \ \__\\ \_\ \____/\ \_\ \_\ \_\ \_\ \__/.\_\\ \_\ \_\\ \____\    \ \_\ \_\ \____/\ \__\/\____/\ \ ,__/\ \____/\ \__\/\____/
        //		 \/___L\ \/____/\/___/   \/__/ \/_/\/___/  \/_/\/_/\/_/\/_/\/__/\/_/ \/_/\/_/ \/____/     \/_/\/_/\/___/  \/__/\/___/  \ \ \/  \/___/  \/__/\/___/
        //		   /\____/                                                                                                              \ \_\
        //		   \_/__/                                                                                                                \/_/

        private function listHotspots():void
        {
            var _jswf:Object = swfJardin.chargeur.content

                for( var i:int = 1 ; i<_jswf.numChildren ; i++)
                {
                    var _hs:Object = _jswf.getChildAt(i)

                        _hs.id = i-1
                        _hs.buttonMode = true;
                    _hs.mouseChildren = false
                        _hs.addEventListener(MouseEvent.MOUSE_OVER, hotspots_MOUSE_OVER)
                        _hs.addEventListener(MouseEvent.MOUSE_OUT, hotspots_MOUSE_OUT)
                        _hs.addEventListener(MouseEvent.MOUSE_DOWN, hotspots_MOUSE_DOWN)
                }
        }

        private function desactiveHotspots():void
        {
            var _jswf:Object = swfJardin.chargeur.content
                for( var i:int = 1 ; i<_jswf.numChildren ; i++)
                {
                    var _hs:Object = _jswf.getChildAt(i)

                        eaze(_hs).delay(.3).to(.3).filter(GlowFilter, { blurX:0, blurY:0, color:0xffffff, alpha:0})

                        _hs.removeEventListener(MouseEvent.MOUSE_OVER, hotspots_MOUSE_OVER)
                        _hs.removeEventListener(MouseEvent.MOUSE_OUT, hotspots_MOUSE_OUT)
                        _hs.removeEventListener(MouseEvent.MOUSE_DOWN, hotspots_MOUSE_DOWN)
                }
        }
        private function hotspots_MOUSE_OVER(e:MouseEvent):void
        {
            var _t:Object = e.currentTarget;

            if(xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].@type == "fiche")
            {
                eaze(_t).to(.15).filter(GlowFilter, { blurX:10, blurY:10, color:0xffffff, alpha:1});
            }
            else if(xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].@type == "transition")
            {
                eaze(_t.hsRoll_mc).to(.15, {alpha:1});
                eaze(_t.hsOff_mc).to(.15, {alpha:0});
            }
            createHotspotLabel(_t, _t.id, xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].@type)
        }
        private function hotspots_MOUSE_OUT(e:MouseEvent):void
        {
            var _t:Object = e.currentTarget;

            if(xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].@type == "fiche")
            {
                eaze(_t).to(.3).filter(GlowFilter, { blurX:0, blurY:0, color:0xffffff, alpha:0})

            }
            else if(xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].@type == "transition")
            {
                eaze(_t.hsRoll_mc).to(.15, {alpha:0});
                eaze(_t.hsOff_mc).to(.15, {alpha:1});
            }

            hideHotspotLabel()
        }
        private function hotspots_MOUSE_DOWN(e:MouseEvent):void
        {
            var _t:Object = e.currentTarget;

            if(xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].@type == "fiche")
            {
                callInfos(_t.id)
                    hideHotspotLabel()
            }
            else if(xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].@type == "transition")
            {
                var _d:* = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_t.id].id_destination
                    removeJardin(_d);
                //desactivePlan();
                getActivePlanPano()
            }
        }


        private function removeJardin(newID:int):void
        {
            var _id:int = newID;
            idPano = _id

                eaze(jardinBox).to(.5, {alpha:0}).onComplete(loadJardin, swfDir+xmlDatas.jardin[idJardin].pano[idPano].pano_dir, jardinBox);
        }

        //		 ___             __              ___               __              __                           __
        //		/\_ \           /\ \            /\_ \             /\ \            /\ \__                       /\ \__
        //		\//\ \      __  \ \ \____     __\//\ \     ____   \ \ \___     ___\ \ ,_\   ____  _____     ___\ \ ,_\   ____
        //		  \ \ \   /'__`\ \ \ '__`\  /'__`\\ \ \   /',__\   \ \  _ `\  / __`\ \ \/  /',__\/\ '__`\  / __`\ \ \/  /',__\
        //		   \_\ \_/\ \L\.\_\ \ \L\ \/\  __/ \_\ \_/\__, `\   \ \ \ \ \/\ \L\ \ \ \_/\__, `\ \ \L\ \/\ \L\ \ \ \_/\__, `\
        //		   /\____\ \__/.\_\\ \_,__/\ \____\/\____\/\____/    \ \_\ \_\ \____/\ \__\/\____/\ \ ,__/\ \____/\ \__\/\____/
        //		   \/____/\/__/\/_/ \/___/  \/____/\/____/\/___/      \/_/\/_/\/___/  \/__/\/___/  \ \ \/  \/___/  \/__/\/___/
        //																							\ \_\
        //																							 \/_/
        private function createHotspotLabel(hs:Object, tid:int, type:String):void
        {
            var _id:int = tid
                var _hs:MovieClip = hs as MovieClip
                var _type:String = type;

            if(_type == "fiche")
            {
                ficheLabel = new fLabel();
                ficheLabel.x = _hs.x + 38;
                ficheLabel.y = _hs.y + 7;

                ficheLabel.label_txt.text = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_id].titre

                    _hs.parent.addChild(ficheLabel)

                    eaze(ficheLabel).from(.25, {alpha:0, x:_hs.x+28}).easing(Cubic.easeOut)
            }
            if(_type == "transition")
            {
                ficheLabel = new pLabel();
                ficheLabel.x = _hs.x - 55;
                ficheLabel.y = _hs.y - 28;

                var _idgo:int = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_id].id_destination
                    ficheLabel.label_txt.text = "Aller au panorama n°"+(_idgo+1)

                    _hs.parent.addChild(ficheLabel)

                    eaze(ficheLabel).from(.25, {alpha:0, y:_hs.y-18}).easing(Cubic.easeOut)
            }

            ficheLabel.mouseEnabled = false;
            ficheLabel.buttonMode = false;
            ficheLabel.mouseChildren = false;

        }
        private function hideHotspotLabel():void
        {
            eaze(ficheLabel).to(.1,{alpha:0})/*.onComplete(removeLabel, _hs)*/
        }
        //							  __
        //							 /\ \__  __                                                                                 __
        //		   __      __    ____\ \ ,_\/\_\    ___     ___       _____      __      ___     ___   _ __    __      ___ ___ /\_\     __   __  __     __
        //		 /'_ `\  /'__`\ /',__\\ \ \/\/\ \  / __`\ /' _ `\    /\ '__`\  /'__`\  /' _ `\  / __`\/\`'__\/'__`\  /' __` __`\/\ \  /'__`\/\ \/\ \  /'__`\
        //		/\ \L\ \/\  __//\__, `\\ \ \_\ \ \/\ \L\ \/\ \/\ \   \ \ \L\ \/\ \L\.\_/\ \/\ \/\ \L\ \ \ \//\ \L\.\_/\ \/\ \/\ \ \ \/\ \L\ \ \ \_\ \/\  __/
        //		\ \____ \ \____\/\____/ \ \__\\ \_\ \____/\ \_\ \_\   \ \ ,__/\ \__/.\_\ \_\ \_\ \____/\ \_\\ \__/.\_\ \_\ \_\ \_\ \_\ \___, \ \____/\ \____\
        //		 \/___L\ \/____/\/___/   \/__/ \/_/\/___/  \/_/\/_/    \ \ \/  \/__/\/_/\/_/\/_/\/___/  \/_/ \/__/\/_/\/_/\/_/\/_/\/_/\/___/\ \/___/  \/____/
        //		   /\____/                                              \ \_\                                                              \ \_\
        //		   \_/__/                                                \/_/                                                               \/_/

        private function configureArrows():void
        {
            switch (panoState)
            {
                case "BUTEE_GAUCHE":
                    eaze(mainBox.leftArrow_mc).to(.5, {alpha: .25});
                    eaze(mainBox.rightArrow_mc).to(.5, {alpha: .75});
                    mainBox.leftArrow_mc.buttonMode = false
                        mainBox.rightArrow_mc.buttonMode = true
                        break;
                case "BUTEE_DROITE":
                    eaze(mainBox.rightArrow_mc).to(.5, {alpha: .25});
                    eaze(mainBox.leftArrow_mc).to(.5, {alpha: .75});
                    mainBox.rightArrow_mc.buttonMode = false
                        mainBox.leftArrow_mc.buttonMode = true
                        break;
                case "MOBILE":
                    eaze(mainBox.leftArrow_mc).to(.5, {alpha: .75});
                    eaze(mainBox.rightArrow_mc).to(.5, {alpha: .75});
                    mainBox.leftArrow_mc.buttonMode = mainBox.rightArrow_mc.buttonMode = true;
                    break;
            }

            mainBox.leftArrow_mc.addEventListener(MouseEvent.MOUSE_OVER, leftArrow_MOUSE_OVER)
                mainBox.leftArrow_mc.addEventListener(MouseEvent.MOUSE_OUT, leftArrow_MOUSE_OUT)
                mainBox.leftArrow_mc.addEventListener(MouseEvent.MOUSE_DOWN, leftArrow_MOUSE_DOWN)

                mainBox.rightArrow_mc.addEventListener(MouseEvent.MOUSE_OVER, rightArrow_MOUSE_OVER)
                mainBox.rightArrow_mc.addEventListener(MouseEvent.MOUSE_OUT, rightArrow_MOUSE_OUT)
                mainBox.rightArrow_mc.addEventListener(MouseEvent.MOUSE_DOWN, rightArrow_MOUSE_DOWN)
        }
        private function desactivateArrows():void
        {
            eaze(mainBox.leftArrow_mc).to(.15, {alpha: .25});
            eaze(mainBox.rightArrow_mc).to(.15, {alpha: .25});

            mainBox.leftArrow_mc.buttonMode = mainBox.rightArrow_mc.buttonMode = false;

            mainBox.leftArrow_mc.removeEventListener(MouseEvent.MOUSE_OVER, leftArrow_MOUSE_OVER)
                mainBox.leftArrow_mc.removeEventListener(MouseEvent.MOUSE_OUT, leftArrow_MOUSE_OUT)
                mainBox.leftArrow_mc.removeEventListener(MouseEvent.MOUSE_DOWN, leftArrow_MOUSE_DOWN)

                mainBox.rightArrow_mc.removeEventListener(MouseEvent.MOUSE_OVER, rightArrow_MOUSE_OVER)
                mainBox.rightArrow_mc.removeEventListener(MouseEvent.MOUSE_OUT, rightArrow_MOUSE_OUT)
                mainBox.rightArrow_mc.removeEventListener(MouseEvent.MOUSE_DOWN, rightArrow_MOUSE_DOWN)
        }

        ///////////////////
        // Gestionnaire
        ///////////////////

        private function leftArrow_MOUSE_OVER(e:MouseEvent):void
        {
            var _t:Object = e.currentTarget;
            if (panoState !== "BUTEE_GAUCHE") eaze(_t).to(.15,{alpha:1});
        }
        private function rightArrow_MOUSE_OVER(e:MouseEvent):void
        {
            var _t:Object = e.currentTarget;
            if (panoState !== "BUTEE_DROITE") eaze(_t).to(.15,{alpha:1});
        }

        private function leftArrow_MOUSE_OUT(e:MouseEvent):void
        {
            var _t:Object = e.currentTarget;
            if (panoState !== "BUTEE_GAUCHE") eaze(_t).to(.4,{alpha:.75});
        }
        private function rightArrow_MOUSE_OUT(e:MouseEvent):void
        {
            var _t:Object = e.currentTarget;
            if (panoState !== "BUTEE_DROITE") eaze(_t).to(.4,{alpha:.75});
        }


        private function leftArrow_MOUSE_DOWN(e:MouseEvent):void
        {
            var _np:int;

            if(panoIndic > 1)
            {
                panoIndic--;
                _np = sceneOrigine[0]-panoFlagsArray[panoIndic]
                    movePano(_np);

                panoState = "MOBILE"

                    eaze(mainBox.rightArrow_mc).to(1,{alpha:.75});
                mainBox.rightArrow_mc.buttonMode = true
            }
            else if(panoIndic == 1)
            {
                panoIndic--;
                _np = sceneOrigine[0]-panoFlagsArray[panoIndic]
                    movePano(_np);

                panoState = "BUTEE_GAUCHE"

                    eaze(mainBox.leftArrow_mc).to(1,{alpha:.25});
                mainBox.leftArrow_mc.buttonMode = false
            }
        }

        private function rightArrow_MOUSE_DOWN(e:MouseEvent):void
        {
            var _np:int;

            if(panoIndic < panoFlagsArray.length-2)
            {
                panoIndic++;
                _np = sceneOrigine[0]-panoFlagsArray[panoIndic];
                movePano(_np);

                panoState = "MOBILE"

                    eaze(mainBox.leftArrow_mc).to(1,{alpha:.75});
                mainBox.leftArrow_mc.buttonMode = true
            }
            else if(panoIndic == panoFlagsArray.length-2)
            {
                panoIndic++;
                _np = sceneOrigine[0]-panoFlagsArray[panoIndic];
                movePano(_np);

                panoState = "BUTEE_DROITE"

                    eaze(mainBox.rightArrow_mc).to(1,{alpha:.25});
                mainBox.rightArrow_mc.buttonMode = false
            }
        }

        //		 ____
        //		/\  _`\
        //		\ \ \L\ \ __      ___     ___          __     __     ____      __
        //		 \ \ ,__/'__`\  /' _ `\  / __`\      /'__`\ /'__`\  /\_ ,`\  /'__`\
        //		  \ \ \/\ \L\.\_/\ \/\ \/\ \L\ \    /\  __//\ \L\.\_\/_/  /_/\  __/
        //		   \ \_\ \__/.\_\ \_\ \_\ \____/    \ \____\ \__/.\_\ /\____\ \____\
        //			\/_/\/__/\/_/\/_/\/_/\/___/      \/____/\/__/\/_/ \/____/\/____/

        private function  movePano(xTarget:Number):void
        {
            eaze(jardinBox).to(.7, {x:xTarget}).easing(Quart.easeInOut)
        }

        //				   ___    ___             __                                      ___             __
        //				 /'___\ /'___\ __        /\ \                                   /'___\ __        /\ \
        //		   __   /\ \__//\ \__//\_\    ___\ \ \___      __       __      __     /\ \__//\_\    ___\ \ \___      __
        //		 /'__`\ \ \ ,__\ \ ,__\/\ \  /'___\ \  _ `\  /'__`\   /'_ `\  /'__`\   \ \ ,__\/\ \  /'___\ \  _ `\  /'__`\
        //		/\ \L\.\_\ \ \_/\ \ \_/\ \ \/\ \__/\ \ \ \ \/\ \L\.\_/\ \L\ \/\  __/    \ \ \_/\ \ \/\ \__/\ \ \ \ \/\  __/
        //		\ \__/.\_\\ \_\  \ \_\  \ \_\ \____\\ \_\ \_\ \__/.\_\ \____ \ \____\    \ \_\  \ \_\ \____\\ \_\ \_\ \____\
        //		 \/__/\/_/ \/_/   \/_/   \/_/\/____/ \/_/\/_/\/__/\/_/\/___L\ \/____/     \/_/   \/_/\/____/ \/_/\/_/\/____/
        //																/\____/
        //																\_/__/

        private function callInfos(ficheID:int):void
        {
            desactivePlan()
                desactiveHotspots()

                var _id:int = ficheID;

            var _title:String = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_id].titre;
            var _title_latin:String = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_id].titre_latin;
            var _texte:String = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_id].texte;
            var _credits:String = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_id].credits;
            var _image_dir:String = xmlDatas.jardin[idJardin].pano[idPano].hotspot[_id].img;

            displayFiche(_title,_title_latin, _texte, _credits, imageDir+_image_dir)
        }

        //////////////////////////////
        /////// Loading
        //////////////////////////////

        private function imgLoad_prog(e:Event):void
        {
            trace(e.target._pourcentage)
        }
        private function imgLoad_end(e:Event):void
        {
            deleteLoadAnimation(ficheActive.x+190)

                var _t:persoLoadFile = e.target as persoLoadFile

                var _bx:Sprite = new Sprite()
                _bx.x = 15;
            _bx.y = 15;

            _bx.addChild(_t)
                ficheActive.addChild(_bx)

                eaze(_bx).from(.6, {alpha:0}).easing(Cubic.easeInOut)
        }

        //////////////////////////////
        /////// Affichage
        //////////////////////////////

        private function displayFiche(ficheTitre:String, ficheTitreLatin:String, ficheTexte:String, creditsTexte:String, imageDir:String):void
        {
            var _fiche:MovieClip = new fiche();

            ficheActive = _fiche;

            _fiche.x = sceneOrigine[0]+146
                _fiche.y = sceneOrigine[1]+183

                _fiche.title_txt.text = ficheTitre.toUpperCase()
                _fiche.title_latin_txt.text = ficheTitreLatin;
            _fiche.texte_txt.htmlText = ficheTexte;
            _fiche.credits_txt.text = creditsTexte;
            _fiche.title_txt.autoSize  = _fiche.title_latin_txt.autoSize = _fiche.texte_txt.autoSize = TextFieldAutoSize.LEFT;

            mainBox.addChildAt(_fiche, numChildren);

            eaze(_fiche).from(.6, {alpha:0}).easing(Cubic.easeInOut).onComplete(confFicheListeners)
                eaze(jardinBox).to(.6).filter(BlurFilter, { blurX:10, blurY:10}).easing(Cubic.easeInOut)

                var _img_load:persoLoadFile = new persoLoadFile(imageDir);
            _img_load.addEventListener("progress", imgLoad_prog);
            _img_load.addEventListener("loaded", imgLoad_end);

            displayLoadAnimation(_fiche.x+190, _fiche.y+144);

            desactivateArrows();
        }

        /////////////////////////////////
        /////// Boutons de fermeture
        /////////////////////////////////

        private function confFicheListeners():void
        {
            ficheActive.close_mc.buttonMode = true;
            ficheActive.close_mc.addEventListener(MouseEvent.MOUSE_OVER, close_MOUSE_OVER)
                ficheActive.close_mc.addEventListener(MouseEvent.MOUSE_OUT, close_MOUSE_OUT)
                ficheActive.close_mc.addEventListener(MouseEvent.MOUSE_DOWN, close_MOUSE_DOWN)

                jardinBox.addEventListener(MouseEvent.MOUSE_DOWN, close_MOUSE_DOWN)
        }
        private function removeFicheListeners():void
        {
            ficheActive.close_mc.removeEventListener(MouseEvent.MOUSE_OVER, close_MOUSE_OVER)
                ficheActive.close_mc.removeEventListener(MouseEvent.MOUSE_OUT, close_MOUSE_OUT)
                ficheActive.close_mc.removeEventListener(MouseEvent.MOUSE_DOWN, close_MOUSE_DOWN)

                jardinBox.removeEventListener(MouseEvent.MOUSE_DOWN, close_MOUSE_DOWN)
        }
        private function close_MOUSE_OVER(e:MouseEvent):void
        {
            // RollOver du bouton close de la fiche
        }
        private function close_MOUSE_OUT(e:MouseEvent):void
        {
            // RollOut du bouton close de la fiche
        }
        private function close_MOUSE_DOWN(e:MouseEvent):void
        {
            //deleteLoadAnimation(ficheActive.x+190);

            eaze(ficheActive).to(.3,{ alpha:0}).onComplete(deleteFiche, ficheActive);
            eaze(jardinBox).to(.3).filter(BlurFilter, { blurX:0, blurY:0}).easing(Cubic.easeInOut)
        }

        //////////////////////////////
        /////// Fermeture
        //////////////////////////////
        private function deleteFiche(obj:MovieClip):void
        {
            mainBox.removeChild(obj);

            listHotspots();
            handlerPlan();

            removeFicheListeners();
            configureArrows();
        }
    }
}





