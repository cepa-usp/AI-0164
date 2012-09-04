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
		private var moleculaFilter:GlowFilter = new GlowFilter(0x800000, 0.5);
		
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
			layerAtividade.setChildIndex(movingObject, layerAtividade.numChildren - 1);
			mouseDiff.x = movingObject.mouseX * movingObject.scaleX;
			mouseDiff.y = movingObject.mouseY * movingObject.scaleY;
			stage.addEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
		}
		
		private var mouseDiff:Point = new Point();
		private function movingMoleculas(e:MouseEvent):void 
		{
			//var posX:Number = stage.mouseX - mouseDiff.x;
			//var posY:Number = stage.mouseY - mouseDiff.y;
			
			movingObject.x = stage.mouseX - mouseDiff.x;//posX;
			movingObject.y = stage.mouseY - mouseDiff.y;//posY;
			
			procuraLigacoes();
		}
		
		private var ligacoes:Vector.<Sprite> = new Vector.<Sprite>();
		private var inicioLigacoes:Dictionary = new Dictionary();
		private var fimLigacoes:Dictionary = new Dictionary();
		private var minDist:Number = 70;
		
		private function procuraLigacoes():void 
		{
			//var vetorDist:Array = getTabela1();
			
			
		}
		
		private function getTabela1():Array
		{
			var arrayElementos:Array = new Array();
			var nElementos:int = getNelementos();
			var auxI:int = 0;
			var auxJ:int = 0;
			
			for (var i:int = 0; i < moleculas.length; i++) 
			{
				for (var j:int = 0; j < moleculas[i].pontosLigacao.length; j++) 
				{
					arrayElementos[auxI] = new Array();
					arrayElementos[auxI][nElementos] = moleculas[i].pontosLigacao[j];
					auxI++;
					auxJ = 0;
					for (var k:int = 0; k < moleculas.length; k++) 
					{
						for (var l:int = 0; l < moleculas[k].pontosLigacao.length; l++) 
						{
							if (moleculas[i].pontosLigacao[j].parent == moleculas[k].pontosLigacao[l].parent) arrayElementos[auxI][auxJ] = Infinity;
							else arrayElementos[auxI][auxJ] = pegaDistancia(moleculas[i].pontosLigacao[j], moleculas[k].pontosLigacao[l]);
							arrayElementos[nElementos][auxJ] = moleculas[k].pontosLigacao[l];
							auxJ++;
						}
					}
				}
			}
		}
		
		private function getTabela():Array
		{
			var nElementos:int = getNelementos() + 1;
			var vetorDistancia:Array = new Array(nElementos, nElementos);
			var auxMoleculaLinha:int = 0;
			var auxMoleculaColuna:int = 0;
			var auxPontoMarcacaoLinha:int = 0;
			var auxPontoMarcacaoColuna:int = 0;
			
			for (var i:int = 0; i < nElementos; i++) 
			{
				if (moleculas[auxMoleculaLinha].pontosLigacao.length == auxPontoMarcacaoLinha) {
					auxMoleculaLinha++;
					auxPontoMarcacaoLinha = 0;
				}
				var ptA:Sprite = moleculas[auxMoleculaLinha].pontosLigacao[auxPontoMarcacaoLinha];
				vetorDistancia[i][vetorDistancia[i].length - 1] = ptA;
				auxPontoMarcacaoLinha++;
				
				loopj: for (var j:int = 0; j < nElementos; j++) 
				{
					if (j < i) {
						if (moleculas[auxMoleculaColuna].pontosLigacao.length == auxPontoMarcacaoColuna) {
							auxMoleculaColuna++;
							auxPontoMarcacaoColuna = 0;
						}
						var ptB:Sprite = moleculas[auxMoleculaColuna].pontosLigacao[auxPontoMarcacaoColuna];
						vetorDistancia[vetorDistancia.length - 1][j] = ptB;
						auxPontoMarcacaoColuna++;
						
						if (ptA.parent == ptB.parent) {
							vetorDistancia[i][j] = Infinity;
						}else {
							vetorDistancia[i][j] = pegaDistancia(ptA, ptB);
						}
						
					}else {
						vetorDistancia[i][j] = Infinity;
						break loopj;
					}
				}
			}
			
			return vetorDistancia;
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
		
		/*private function procuraLigacoes():void 
		{
			if (moleculas.length <= 1) return;
			
			ligacoes.splice(0, ligacoes.length);
			inicioLigacoes = new Dictionary();
			fimLigacoes = new Dictionary();
			
			var localMinDist:Number;
			var ptDepDef:Sprite;
			
			for (var i:int = 0; i < moleculas.length - 1; i++) 
			{
				//Para todas as moléculas, menos a última:
				//Pega a molécula na posição i.
				var molAnt:Molecula = moleculas[i];
				//Para cada ponto de ligação da molécula i faça:
				for (var j:int = 0; j < molAnt.pontosLigacao.length; j++) 
				{
					//Pega o ponto de ligação j;
					var ptAnt:Sprite = molAnt.pontosLigacao[j];
					//Seta a distancia minima para infinito.
					localMinDist = Infinity;
					
					//Percorre o restante das moléculas do array.
					for (var k:int = i+1; k < moleculas.length; k++) 
					{
						//Pega a molécula k (depois da i)
						var molDep:Molecula = moleculas[k];
						//Percorre todas os pontos de ligação dessa molécula
						for (var l:int = 0; l < molDep.pontosLigacao.length; l++) 
						{
							//Pega o ponto de ligação l
							var ptDep:Sprite = molDep.pontosLigacao[l];
							//Verifica se o ponto de ligação l e o ponto de ligação j são do mesmo tipo
							if ((ptAnt is MarcacaoCovalente && ptDep is MarcacaoCovalente) || (ptAnt is MarcacaoPonte && ptDep is MarcacaoPonte)) {
								if(fimLigacoes[ptDep] == null && inicioLigacoes[ptDep] == null){
									//Calcula a distância entre os pontos de ligação
									var dist:Number = pegaDistancia(ptAnt, ptDep);
									//Se a distância entre esses pontos de ligação for menor que a calculada anteriormente
									if (dist < localMinDist) {
										//Atualiza os dados da menor distância.
										localMinDist = dist;
										ptDepDef = ptDep;
									}
								}
							}
						}
					}
					
					if (localMinDist <= minDist) {
						ligacoes.push(ptAnt);
						inicioLigacoes[ptAnt] = ptDepDef;
						fimLigacoes[ptDepDef] = ptAnt;
					}
				}
			}
			
			/*for each (var ptMoving:Sprite in movingObject.pontosLigacao) 
			{
				for each (var moleculaParada:Molecula in moleculas) 
				{
					if (moleculaParada != movingObject){
						for each (var ptParado:Sprite in moleculaParada.pontosLigacao) 
						{
							
							if ((ptMoving is MarcacaoCovalente && ptParado is MarcacaoCovalente) || (ptMoving is MarcacaoPonte && ptParado is MarcacaoPonte)) {
								//Verifica se os pontos que serão comparados são do mesmo tipo.
								if (!temLigacoes(ptMoving) && !temLigacoes(ptParado)) {
									//Se não existir ligação com esses pontos:
									if (pegaDistancia(ptParado, ptMoving) <= minDist) {
										//Cria uma nova lgacao:
										inicioLigacoes[ptMoving] = ptParado;
										fimLigacoes[ptParado] = ptMoving;
										ligacoes.push(ptMoving);
									}
								}
							}
							
						}
					}
				}
			}*/
		/*	
			desenhaLigacoes();
		}*/
		
		private function temLigacoes(spr:Sprite):Boolean
		{
			if (ligacoes.indexOf(spr) >= 0) {
				//Se já existir uma ligação nesse ponto, e o ponto é o inicio da ligacao:
				if (pegaDistancia(spr, inicioLigacoes[spr]) > minDist) {
					//Se a distancia de ligação entre eles for maior que a distância mínima, remove a ligação.
					var fimLigacao:Sprite = inicioLigacoes[spr];
					inicioLigacoes[spr] = null;
					fimLigacoes[fimLigacao] = null;
					ligacoes.splice(ligacoes.indexOf(spr), 1);
					return false;
				}else {
					return true;
				}
			}else if (fimLigacoes[spr] != null) {
				//Se já existir uma ligação nesse ponto, e o ponto é o fim da ligacao:
				if (pegaDistancia(spr, fimLigacoes[spr]) > minDist) {
					//Se a distancia de ligação entre eles for maior que a distância mínima, remove a ligação.
					var inicioLigacao:Sprite = fimLigacoes[spr];
					inicioLigacoes[inicioLigacao] = null;
					fimLigacoes[spr] = null;
					ligacoes.splice(ligacoes.indexOf(inicioLigacao), 1);
					return false;
				}else {
					return true;
				}
			}
			return false;
		}
		
		private function pegaDistancia(spr1:Sprite, spr2:Sprite):Number
		{
			var ptSpr1:Point = spr1.parent.localToGlobal(new Point(spr1.x, spr1.y));
			var ptSpr2:Point = spr2.parent.localToGlobal(new Point(spr2.x, spr2.y));
			//return Point.distance(new Point((spr1.x * spr1.scaleY) + spr1.parent.x, (spr1.y * spr1.scaleX) + spr1.parent.y), new Point((spr2.x * spr2.scaleY) + spr2.parent.x, (spr2.y + spr2.scaleX) + spr2.parent.y));
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
					//dashTo(spriteLigacoes.graphics, (item.x * item.scaleY) + item.parent.x, (item.y + item.scaleX) + item.parent.y, (end.x * end.scaleY) + end.parent.x, (end.y * end.scaleX) + end.parent.y, dashLen, dashGap);
					dashTo(spriteLigacoes.graphics, ptSpr1.x, ptSpr1.y, ptSpr2.x, ptSpr2.y, dashLen, dashGap);
				}else {
					spriteLigacoes.graphics.lineStyle(lineTickness, colorCovalente);
					//spriteLigacoes.graphics.moveTo((item.x * item.scaleY) + item.parent.x, (item.y * item.scaleX) + item.parent.y);
					//spriteLigacoes.graphics.lineTo((end.x * end.scaleY) + end.parent.x, (end.y * end.scaleX) + end.parent.y);
					spriteLigacoes.graphics.moveTo(ptSpr1.x, ptSpr1.y);
					spriteLigacoes.graphics.lineTo(ptSpr2.x, ptSpr2.y);
				}
			}
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