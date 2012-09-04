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
	import flash.display.Graphics;
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
	import flash.utils.Dictionary;
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
		private var moleculaFilter:GlowFilter = new GlowFilter(0x000000, 0.8, 10, 10);
		
		private var colorCovalente:uint = 0x000000;
		private var colorPonte:uint = 0xFF0000;
		private var lineTickness:int = 2;
		
		private var spriteLigacoes:Sprite;
		
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
			spriteLigacoes = new Sprite();
			layerAtividade.addChild(spriteLigacoes);
			lock(opcoes.hInvert);
			lock(opcoes.vInvert);
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
					lock(opcoes.hInvert);
					lock(opcoes.vInvert);
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
					procuraLigacoes();
					return;
				case "vInvert":
					inverteObjeto(movingObject, "v");
					procuraLigacoes();
					return;
				default:
					return;
			}
			
			newObj.scaleX = newObj.scaleY = 0.75;
			newObj.addEventListener(MouseEvent.MOUSE_DOWN, downMoleculasListener);
			moleculas.push(newObj);
			layerAtividade.addChild(newObj);
			layerAtividade.setChildIndex(spriteLigacoes, layerAtividade.numChildren - 1);
			
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
				lock(opcoes.hInvert);
				lock(opcoes.vInvert);
			}
		}
		
		private var permiteTween:Boolean = true;
		private function inverteObjeto(target:MovieClip, direcao:String):void 
		{
			if (!permiteTween) return;
			if (direcao == "h") {
				Actuate.tween(target, 0.3, { scaleX:target.scaleX * -1 } ).onComplete(liberaTween);
			}else {
				//target.scaleY *= -1;
				Actuate.tween(target, 0.3, {rotation:target.rotation + 72}).onComplete(liberaTween);
			}
			permiteTween = false;
		}
		
		private function liberaTween():void 
		{
			permiteTween = true;
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
			layerAtividade.setChildIndex(movingObject, layerAtividade.numChildren - 1);
			layerAtividade.setChildIndex(spriteLigacoes, layerAtividade.numChildren - 1);
			mouseDiff.x = movingObject.mouseX * movingObject.scaleX;
			mouseDiff.y = movingObject.mouseY * movingObject.scaleY;
			stage.addEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
		}
		
		private var mouseDiff:Point = new Point();
		private function movingMoleculas(e:MouseEvent):void 
		{
			movingObject.x = Math.min(690, Math.max(10, stage.mouseX - mouseDiff.x));
			movingObject.y = Math.min(590, Math.max(10, stage.mouseY - mouseDiff.y));
			
			procuraLigacoes();
		}
		
		private var ligacoes:Vector.<Sprite> = new Vector.<Sprite>();
		private var inicioLigacoes:Dictionary = new Dictionary();
		private var fimLigacoes:Dictionary = new Dictionary();
		private var minDist:Number = 70;
		
		private function procuraLigacoes():void 
		{
			ligacoes.splice(0, ligacoes.length);
			inicioLigacoes = new Dictionary();
			fimLigacoes = new Dictionary();
			
			var vetorDist:Array = getTabela();
			var nElementos:int = getNelementos();
			
			var triple:Array = getMinDist(vetorDist);
			while (triple[2] <= minDist) 
			{
				if(inicioLigacoes[triple[0]] == null && inicioLigacoes[triple[1]] == null && fimLigacoes[triple[0]] == null && fimLigacoes[triple[1]] == null){
					ligacoes.push(triple[0]);
					inicioLigacoes[triple[0]] = triple[1];
					fimLigacoes[triple[1]] = triple[0];
				}
				triple = getMinDist(vetorDist);
			}
			
			desenhaLigacoes();
		}
		
		private function getMinDist(vetorDist:Array):Array
		{
			var indexI:int;
			var indexJ:int;
			var distanciaMinima:Number = Infinity;
			
			for (var i:int = 0; i < vetorDist.length - 1; i++) 
			{
				look: for (var j:int = 0; j < vetorDist[i].length - 1; j++) 
				{
					if (j < i) {
						if (vetorDist[i][j] < distanciaMinima) {
							indexI = i;
							indexJ = j;
							distanciaMinima = vetorDist[i][j];
						}
					}else {
						break look;
					}
				}
			}
			
			for (var k:int = 0; k < vetorDist[indexI].length - 1; k++) 
			{
				vetorDist[indexI][k] = Infinity;
			}
			
			for (var l:int = 0; l < vetorDist.length - 1; l++) 
			{
				vetorDist[l][indexJ] = Infinity;
			}
			
			var arrReturn:Array = [vetorDist[indexI][vetorDist[indexI].length - 1], vetorDist[vetorDist.length - 1][indexJ], distanciaMinima];
			
			return arrReturn;
		}
		
		private function getTabela():Array
		{
			var nElementos:int = getNelementos();
			var arrayElementos:Array = new Array();
			var auxI:int = 0;
			var auxJ:int = 0;
			arrayElementos[nElementos] = new Array();
			for (var i:int = 0; i < moleculas.length; i++) 
			{
				for (var j:int = 0; j < moleculas[i].pontosLigacao.length; j++) 
				{
					arrayElementos[auxI] = new Array();
					arrayElementos[auxI][nElementos] = moleculas[i].pontosLigacao[j];
					auxJ = 0;
					for (var k:int = 0; k < moleculas.length; k++) 
					{
						for (var l:int = 0; l < moleculas[k].pontosLigacao.length; l++) 
						{
							if (moleculas[i].pontosLigacao[j].parent == moleculas[k].pontosLigacao[l].parent) {
								arrayElementos[auxI][auxJ] = Infinity;
							}else {
								if ((moleculas[i].pontosLigacao[j] is MarcacaoCovalente && moleculas[k].pontosLigacao[l] is MarcacaoCovalente) || 
									(moleculas[i].pontosLigacao[j] is MarcacaoPonte && moleculas[k].pontosLigacao[l] is MarcacaoPonte)) {
										arrayElementos[auxI][auxJ] = pegaDistancia(moleculas[i].pontosLigacao[j], moleculas[k].pontosLigacao[l]);
									}else {
										arrayElementos[auxI][auxJ] = Infinity;
									}
								
							}
							arrayElementos[nElementos][auxJ] = moleculas[k].pontosLigacao[l];
							auxJ++;
						}
					}
					auxI++;
				}
			}
			
			return arrayElementos;
		}
		
		private function getNelementos():int
		{
			var nEl:int = 0;
			for each (var item:Molecula in moleculas) 
			{
				nEl += item.pontosLigacao.length;
			}
			
			return nEl;
		}
		
		private function pegaDistancia(spr1:Sprite, spr2:Sprite):Number
		{
			var ptSpr1:Point = spr1.parent.localToGlobal(new Point(spr1.x, spr1.y));
			var ptSpr2:Point = spr2.parent.localToGlobal(new Point(spr2.x, spr2.y));
			return Point.distance(ptSpr1, ptSpr2);
		}
		
		private var dashLen:Number = 3;
		private var dashGap:Number = 3;
		private function desenhaLigacoes():void 
		{
			spriteLigacoes.graphics.clear();
			var end:Sprite;
			
			for each (var item:Sprite in ligacoes) 
			{
				end = inicioLigacoes[item];
				var ptSpr1:Point = item.parent.localToGlobal(new Point(item.x, item.y));
				var ptSpr2:Point = end.parent.localToGlobal(new Point(end.x, end.y));
				if (item is MarcacaoPonte) {
					spriteLigacoes.graphics.lineStyle(lineTickness, colorPonte);
					dashTo(spriteLigacoes.graphics, ptSpr1.x, ptSpr1.y, ptSpr2.x, ptSpr2.y, dashLen, dashGap);
				}else {
					spriteLigacoes.graphics.lineStyle(lineTickness, colorCovalente);
					spriteLigacoes.graphics.moveTo(ptSpr1.x, ptSpr1.y);
					spriteLigacoes.graphics.lineTo(ptSpr2.x, ptSpr2.y);
				}
			}
		}
		
		private function upMoleculasListener(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
			stage.removeEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			
			if (movingObject.y > 530) {
				moleculas.splice(moleculas.indexOf(movingObject), 1);
				layerAtividade.removeChild(movingObject);
				movingObject = null;
			}else {
				movingObject.filters = [moleculaFilter];
				unlock(opcoes.hInvert);
				unlock(opcoes.vInvert);
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
			for each (var item:Molecula in moleculas) 
			{
				layerAtividade.removeChild(item);
			}
			
			moleculas.splice(0, moleculas.length);
			spriteLigacoes.graphics.clear();
			lock(opcoes.hInvert);
			lock(opcoes.vInvert);
			
			if(connected){
				if (completed) return;
			}else {
				if (completed) completed = false;
				score = 0;
			}
			
			saveStatus();
		}
		
		private function dashTo (graphics:Graphics, startx:Number, starty:Number, endx:Number, endy:Number, len:Number, gap:Number) : void {
			
			// init vars
			var seglength, delta, deltax, deltay, segs, cx, cy, radians;
			// calculate the legnth of a segment
			seglength = len + gap;
			// calculate the length of the dashed line
			deltax = endx - startx;
			deltay = endy - starty;
			delta = Math.sqrt((deltax * deltax) + (deltay * deltay));
			// calculate the number of segments needed
			segs = Math.floor(Math.abs(delta / seglength));
			// get the angle of the line in radians
			radians = Math.atan2(deltay,deltax);
			// start the line here
			cx = startx;
			cy = starty;
			// add these to cx, cy to get next seg start
			deltax = Math.cos(radians)*seglength;
			deltay = Math.sin(radians)*seglength;
			// loop through each seg
			for (var n = 0; n < segs; n++) {
				graphics.moveTo(cx,cy);
				graphics.lineTo(cx+Math.cos(radians)*len,cy+Math.sin(radians)*len);
				cx += deltax;
				cy += deltay;
			}
			// handle last segment as it is likely to be partial
			graphics.moveTo(cx,cy);
			delta = Math.sqrt((endx-cx)*(endx-cx)+(endy-cy)*(endy-cy));
			if(delta>len){
				// segment ends in the gap, so draw a full dash
				graphics.lineTo(cx+Math.cos(radians)*len,cy+Math.sin(radians)*len);
			} else if(delta>0) {
				// segment is shorter than dash so only draw what is needed
				graphics.lineTo(cx+Math.cos(radians)*delta,cy+Math.sin(radians)*delta);
			}
			// move the pen to the end position
			graphics.moveTo(endx,endy);
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
								"Clique e arrste sobre uma molécula para criá-la.",
								"Posicione as moléculas para montar um segmento de DNA.",
								"Ao movimentar as moléculas serão formadas as ligações (covalente ou ponte de hidrogênio)...",
								"...de acordo com a proximidade entre os elementos que formam a ligação.",
								"Pressione \"terminei\" para avaliar sua resposta."];
				
				pointsTuto = 	[new Point(590, 500),
								new Point(190 , 530),
								new Point(180 , 180),
								new Point(220 , 220),
								new Point(290 , 260),
								new Point(finaliza.x, finaliza.y + finaliza.height / 2)];
								
				tutoBaloonPos = [[CaixaTexto.RIGHT, CaixaTexto.FIRST],
								[CaixaTexto.BOTTON, CaixaTexto.FIRST],
								["", ""],
								["", ""],
								["", ""],
								[CaixaTexto.TOP, CaixaTexto.FIRST]];
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