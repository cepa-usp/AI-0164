package 
{
	import BaseAssets.BaseMain;
	import BaseAssets.events.BaseEvent;
	import BaseAssets.tutorial.CaixaTexto;
	import com.adobe.serialization.json.JSON;
	import cepa.utils.ToolTip;
	import com.eclecticdesignstudio.motion.Actuate;
	import com.eclecticdesignstudio.motion.easing.Linear;
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.Timer;
	import pipwerks.SCORM;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Main extends BaseMain
	{
		private var moleculas:Vector.<Molecula> = new Vector.<Molecula>();
		private var moleculaFilter:GlowFilter = new GlowFilter(0x800000, 0.5);
		
		override protected function init():void 
		{
			organizeLayers();
			addListeners();
			createAnswer();
			
			if (ExternalInterface.available) {
				initLMSConnection();
				if (mementoSerialized != null) {
					if(mementoSerialized != "" && mementoSerialized != "null") recoverStatus(mementoSerialized);
				}
			}
			
			if (connected) {
				if (scorm.get("cmi.entry") == "ab-initio") iniciaTutorial();
			}else {
				if (score == 0) iniciaTutorial();
			}
		}
		
		private function organizeLayers():void 
		{
			layerAtividade.addChild(entrada);
			layerAtividade.addChild(finaliza);
			layerAtividade.addChild(opcoes);
		}
		
		private function addListeners():void 
		{
			finaliza.addEventListener(MouseEvent.CLICK, finalizaExec);
			finaliza.buttonMode = true;
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, downStage);
			opcoes.addEventListener(MouseEvent.MOUSE_DOWN, downOpcoes);
		}
		
		private function downStage(e:MouseEvent):void 
		{
			if (e.target is Stage) {
				if (movingObject != null) {
					movingObject.filters = [];
					movingObject = null;
				}
			}
		}
		
		private var movingObject:Molecula;
		private function downOpcoes(e:MouseEvent):void 
		{
			var newObj:Molecula;
			switch (e.target.name) {
				case "fosfato":
					newObj = new Fosfato();
					break;
				case "basePirimidica":
					newObj = new BasePirimidica();
					break;
				case "basePurica":
					newObj = new BasePurica();
					break;
				case "pentose":
					newObj = new Pentose();
					break;
				case "hInvert":
					inverteObjeto(movingObject, "h");
					return;
				case "vInvert":
					inverteObjeto(movingObject, "v");
					return;
				default:
					return;
			}
			
			newObj.addEventListener(MouseEvent.MOUSE_DOWN, downMoleculasListener);
			moleculas.push(newObj);
			layerAtividade.addChild(newObj);
			
			removeSelection();
			movingObject = newObj;
			movingObject.x = stage.mouseX;
			movingObject.y = stage.mouseY;
			mouseDiff.x = 0;
			mouseDiff.y = 0;
			stage.addEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
		}
		
		private function removeSelection():void
		{
			if (movingObject != null) {
				movingObject.filters = [];
				movingObject = null;
			}
		}
		
		private function inverteObjeto(target:MovieClip, direcao:String):void 
		{
			if (direcao == "h") {
				target.scaleX *= -1;
			}else {
				target.scaleY *= -1;
			}
		}
		
		private function finalizaExec(e:MouseEvent):void 
		{
			
		}
		
		private function createAnswer():void 
		{
			
		}
		
		private function downMoleculasListener(e:MouseEvent):void 
		{
			removeSelection();
			movingObject = Molecula(e.target);
			mouseDiff.x = movingObject.mouseX;
			mouseDiff.y = movingObject.mouseY;
			stage.addEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
		}
		
		private var mouseDiff:Point = new Point();
		private function movingMoleculas(e:MouseEvent):void 
		{
			var posX:Number = stage.mouseX - mouseDiff.x;
			var posY:Number = stage.mouseY - mouseDiff.y;
			
			
			
			movingObject.x = posX;
			movingObject.y = posY;
		}
		
		private function upMoleculasListener(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
			stage.removeEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			
			if (MovieClip(opcoes).hitTestPoint(movingObject.x, movingObject.y)) {
				moleculas.splice(moleculas.indexOf(movingObject), 1);
				layerAtividade.removeChild(movingObject);
				movingObject = null;
			}else {
				movingObject.filters = [moleculaFilter];
			}
		}
		
		
		private function saveStatusForRecovery(e:MouseEvent = null):void
		{
			var status:Object = new Object();
			
			status.completed = completed;
			status.score = score;
			
			mementoSerialized = JSON.encode(status);
		}
		
		private function recoverStatus(memento:String):void
		{
			var status:Object = JSON.decode(memento);
			
			if (!connected) {
				completed = status.completed;
				score = status.score;
			}
		}
		
		override public function reset(e:MouseEvent = null):void
		{
			if(connected){
				if (completed) return;
			}else {
				if (completed) completed = false;
				score = 0;
			}
			
			saveStatus();
		}
		
		
		//---------------- Tutorial -----------------------
		
		private var balao:CaixaTexto;
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var tutoSequence:Array;
		
		override public function iniciaTutorial(e:MouseEvent = null):void  
		{
			blockAI();
			
			tutoPos = 0;
			if(balao == null){
				balao = new CaixaTexto();
				layerTuto.addChild(balao);
				balao.visible = false;
				
				tutoSequence = ["Veja aqui as orientações.",
								"Arraste as \"Causas\" e \"Consequências\" para os locais corretos.", 
								"Pressione \"terminei\" para avaliar sua resposta."];
				
				pointsTuto = 	[new Point(565, 555),
								new Point(315 , 250),
								new Point(finaliza.x, finaliza.y - finaliza.height / 2)];
								
				tutoBaloonPos = [[CaixaTexto.BOTTON, CaixaTexto.LAST],
								["", ""],
								[CaixaTexto.BOTTON, CaixaTexto.FIRST]];
			}
			balao.removeEventListener(BaseEvent.NEXT_BALAO, closeBalao);
			
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(BaseEvent.NEXT_BALAO, closeBalao);
			balao.addEventListener(BaseEvent.CLOSE_BALAO, iniciaAi);
		}
		
		private function closeBalao(e:Event):void 
		{
			tutoPos++;
			if (tutoPos >= tutoSequence.length) {
				balao.removeEventListener(BaseEvent.NEXT_BALAO, closeBalao);
				balao.visible = false;
				iniciaAi(null);
			}else {
				balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
				balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			}
		}
		
		private function iniciaAi(e:BaseEvent):void 
		{
			balao.removeEventListener(BaseEvent.CLOSE_BALAO, iniciaAi);
			balao.removeEventListener(BaseEvent.NEXT_BALAO, closeBalao);
			unblockAI();
		}
		
		
		/*------------------------------------------------------------------------------------------------*/
		//SCORM:
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormExercise:int;
		private var connected:Boolean;
		private var score:int = 0;
		private var pingTimer:Timer;
		private var mementoSerialized:String = "";
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			pingTimer = new Timer(PING_INTERVAL);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			
			connected = scorm.connect();
			
			if (connected) {
				
				if (scorm.get("cmi.mode" != "normal")) return;
				
				scorm.set("cmi.exit", "suspend");
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");	
				mementoSerialized = scorm.get("cmi.suspend_data");
				var stringScore:String = scorm.get("cmi.score.raw");
				
				switch(status)
				{
					// Primeiro acesso à AI
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						break;
					
					// Continuando a AI...
					case "incomplete":
						completed = false;
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						//setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				
				//unmarshalObjects(mementoSerialized);
				
				scormExercise = int(scorm.get("cmi.location"));
				score = Number(stringScore.replace(",", "."));
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					pingTimer.start();
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				trace("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
				mementoSerialized = ExternalInterface.call("getLocalStorageString");
			}
			
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function commit()
		{
			if (connected)
			{
				if (scorm.get("cmi.mode" != "normal")) return;
				
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());
				
				// Salva no LMS a string que representa a situação atual da AI para ser recuperada posteriormente.
				//mementoSerialized = marshalObjects();
				success = scorm.set("cmi.suspend_data", mementoSerialized.toString());
				
				if (score > 99) success = scorm.set("cmi.success_status", "passed");
				else success = scorm.set("cmi.success_status", "failed");

				if (success)
				{
					scorm.save();
				}
				else
				{
					pingTimer.stop();
					//setMessage("Falha na conexão com o LMS.");
					connected = false;
				}
			}else { //LocalStorage
				ExternalInterface.call("save2LS", mementoSerialized);
			}
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent)
		{
			//scorm.get("cmi.completion_status");
			commit();
		}
		
		private function saveStatus(e:Event = null):void
		{
			if (ExternalInterface.available) {
				if (connected) {
					
					if (scorm.get("cmi.mode" != "normal")) return;
					
					saveStatusForRecovery();
					scorm.set("cmi.suspend_data", mementoSerialized);
					commit();
				}else {//LocalStorage
					saveStatusForRecovery();
					ExternalInterface.call("save2LS", mementoSerialized);
				}
			}
		}
		
	}

}