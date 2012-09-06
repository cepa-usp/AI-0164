package 
{
	import BaseAssets.BaseMain;
	import BaseAssets.events.BaseEvent;
	import BaseAssets.tutorial.CaixaTexto;
	import com.adobe.serialization.json.JSON;
	import cepa.utils.ToolTip;
	import com.eclecticdesignstudio.motion.Actuate;
	import com.eclecticdesignstudio.motion.easing.Linear;
	import fl.controls.RadioButton;
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
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
		private var tiposLigacoes:Vector.<MovieClip> = new Vector.<MovieClip>();
		
		private var moleculaFilter:GlowFilter = new GlowFilter(0x000000, 0.8, 10, 10);
		private var ligacaoFilter:GlowFilter = new GlowFilter(0x000000, 0.8, 10, 10, 4);
		private var erroFilter:GlowFilter = new GlowFilter(0xFF0000, 1, 12, 12);
		private var erroFilterLig:GlowFilter = new GlowFilter(0xFF0000, 1, 8, 8, 5, 3, false, false);
		
		private var colorCovalente:uint = 0x000000;
		private var colorPonte:uint = 0xFF0000;
		private var colorIndefinido:uint = 0xC0C0C0;
		
		private var colors:Dictionary = new Dictionary();
		
		private var lineTickness:int = 2;
		
		//private var spriteLigacoes:Sprite;
		private var spriteLigacoes:Vector.<Sprite> = new Vector.<Sprite>();
		private var arrayElementos:Array = [];
		
		private var minFosfato:int = 6;
		private var minPentose:int = 6;
		private var minPirimidica:int = 3;
		private var minPurica:int = 3;
		
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
		
		private var posInicialMenuLigacao:Number = 602;
		private var posFinalMenuLigacao:Number = 790;
		
		private function organizeLayers():void 
		{
			layerAtividade.addChild(entrada);
			layerAtividade.addChild(finaliza);
			layerAtividade.addChild(opcoes);
			layerAtividade.addChild(menuTipoLigacao);
			//menuTipoLigacao.visible = false;
			menuTipoLigacao.x = posFinalMenuLigacao;
			menuTipoLigacao.indefinido.visible = true;
			//spriteLigacoes = new Sprite();
			//layerAtividade.addChild(spriteLigacoes);
			lock(opcoes.hInvert);
			lock(opcoes.vInvert);
			
			colors[Molecula.TIPO_COVALENTE] = colorCovalente;
			colors[Molecula.TIPO_PONTE] = colorPonte;
			colors[Molecula.TIPO_INDEFINIDO] = colorIndefinido;
			
			opcoes.fosfato.buttonMode = true;
			opcoes.basePirimidica.buttonMode = true;
			opcoes.basePurica.buttonMode = true;
			opcoes.pentose.buttonMode = true;
		}
		
		private function addListeners():void 
		{
			finaliza.addEventListener(MouseEvent.CLICK, finalizaExec);
			finaliza.buttonMode = true;
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, downStage);
			opcoes.addEventListener(MouseEvent.MOUSE_DOWN, downOpcoes);
			
			menuTipoLigacao.addEventListener(MouseEvent.CLICK, menuLigacaoClick);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyUpEvent);
		}
		
		private function keyUpEvent(e:KeyboardEvent):void 
		{
			//trace(e.keyCode);
			if (e.keyCode == Keyboard.DELETE) {
				if (movingObject != null) {
					layerAtividade.removeChild(movingObject);
					moleculas.splice(moleculas.indexOf(movingObject), 1);
					movingObject = null;
					lock(opcoes.hInvert);
					lock(opcoes.vInvert);
					procuraLigacoes();
				}
			}else if(e.keyCode == Keyboard.R){
				recoverStatus(mementoSerialized);
			}
		}
		
		private function menuLigacaoClick(e:MouseEvent):void 
		{
			if(!e.target is RadioButton) return;
			if (ligacaoSelecionada != null) {
				
				var sprIni:Sprite = ligacoes[spriteLigacoes.indexOf(ligacaoSelecionada)];
				var sprFim:Sprite = inicioLigacoes[sprIni];
				
				var tipo:String = e.target.name;
				
				Molecula(sprIni.parent).setTipoLigacao(sprIni, tipo);
				Molecula(sprFim.parent).setTipoLigacao(sprFim, tipo);
				
				redesenhaSpr(ligacaoSelecionada);
				saveStatus();
			}
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
				
				if (ligacaoSelecionada != null) {
					ligacaoSelecionada.filters = [];
					//menuTipoLigacao.visible = false;
					Actuate.tween(menuTipoLigacao, 0.3, { x:posFinalMenuLigacao } );
					ligacaoSelecionada = null;
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
			
			newObj.tipo = e.target.name;
			var tt:ToolTip = new ToolTip(newObj, pegaTipo(e.target.name), 10, 0.8, 100, 0.2, 0.2);
			layerAtividade.addChild(tt);
			newObj.scaleX = newObj.scaleY = 0.75;
			newObj.addEventListener(MouseEvent.MOUSE_DOWN, downMoleculasListener);
			moleculas.push(newObj);
			layerAtividade.addChild(newObj);
			//layerAtividade.setChildIndex(spriteLigacoes, layerAtividade.numChildren - 1);
			
			removeSelection();
			movingObject = newObj;
			movingObject.x = stage.mouseX;
			movingObject.y = stage.mouseY;
			mouseDiff.x = 0;
			mouseDiff.y = 0;
			stage.addEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
		}
		
		private function criaObjeto(tipo:String, posX:Number, posY:Number, rotacao:Number = 0, scaleX:Number = NaN, scaleY:Number = NaN):Molecula
		{
			var newObj:Molecula;
			switch (tipo) {
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
			}
			
			newObj.tipo = tipo;
			var tt:ToolTip = new ToolTip(newObj, pegaTipo(tipo), 10, 0.8, 100, 0.2, 0.2);
			layerAtividade.addChild(tt);
			if (isNaN(scaleX)) newObj.scaleX = 0.75;
			else newObj.scaleX = scaleX;
			if (isNaN(scaleY)) newObj.scaleY = 0.75;
			else newObj.scaleY = scaleY;
			newObj.x = posX;
			newObj.y = posY;
			newObj.rotation = rotacao;
			newObj.addEventListener(MouseEvent.MOUSE_DOWN, downMoleculasListener);
			moleculas.push(newObj);
			layerAtividade.addChild(newObj);
			
			return newObj;
			//layerAtividade.setChildIndex(spriteLigacoes, layerAtividade.numChildren - 1);
		}
		
		private function pegaTipo(tipo:String):String 
		{
			switch (tipo) {
				case "fosfato":
					return "Fosfato";
					break;
				case "basePirimidica":
					return "Base pirimídica";
					break;
				case "basePurica":
					return "Base púrica";
					break;
				case "pentose":
					return "Pentose";
					break;
			}
			
			return "";
		}
		
		private function removeSelection():void
		{
			if (movingObject != null) {
				movingObject.filters = [];
				movingObject = null;
				lock(opcoes.hInvert);
				lock(opcoes.vInvert);
			}
			
			if (ligacaoSelecionada != null) {
				ligacaoSelecionada.filters = [];
				//menuTipoLigacao.visible = false;
				Actuate.tween(menuTipoLigacao, 0.3, { x:posFinalMenuLigacao } );
				ligacaoSelecionada = null;
			}
			
			for each (var item:Molecula in moleculas) 
			{
				item.filters = [];
			}
			
			for each (var item2:Sprite in spriteLigacoes) 
			{
				item2.filters = [];
			}
			errorFilterOn = false;
		}
		
		private var permiteTween:Boolean = true;
		private function inverteObjeto(target:MovieClip, direcao:String):void 
		{
			if (!permiteTween) return;
			//spriteLigacoes.graphics.clear();
			removeSprites();
			if (direcao == "h") {
				Actuate.tween(target, 0.3, { scaleX:target.scaleX * -1 } ).onComplete(liberaTween);
			}else {
				//target.scaleY *= -1;
				Actuate.tween(target, 0.3, {rotation:target.rotation - 72}).onComplete(liberaTween);
			}
			permiteTween = false;
		}
		
		private function liberaTween():void 
		{
			permiteTween = true;
			procuraLigacoes();
			saveStatus();
		}
		
		private var errorFilterOn:Boolean = false;
		private function finalizaExec(e:MouseEvent):void 
		{
			removeSelection();
			
			var qtd:Dictionary = new Dictionary();
			qtd["fosfato"] = 0;
			qtd["basePirimidica"] = 0;
			qtd["basePurica"] = 0;
			qtd["pentose"] = 0;
			
			var acertosMol:int = 0;
			var totalMol:int = 0;
			for (var i:int = 0; i < moleculas.length; i++) 
			{
				var molInicial:Molecula = moleculas[i];
				if (molInicial.temLigacao()) {
					totalMol++;
					switch (molInicial.tipo) {
						case "fosfato":
							if (analisaFosfato(molInicial)) acertosMol++;
							else molInicial.filters = [erroFilter];
							break;
						case "basePirimidica":
							if (analisaBase(molInicial)) acertosMol++;
							else molInicial.filters = [erroFilter];
							break;
						case "basePurica":
							if (analisaBase(molInicial)) acertosMol++;
							else molInicial.filters = [erroFilter];
							break;
						case "pentose":
							if (analisaPentose(molInicial)) acertosMol++;
							else molInicial.filters = [erroFilter];
							break;
					}
					qtd[molInicial.tipo] += 1;
				}
			}
			
			var scoreMoleculas:int = Math.round(acertosMol / totalMol * 100);
			
			var acertosLig:int = 0;
			var totalLig:int = 0;
			for (var j:int = 0; j < ligacoes.length; j++) 
			{
				totalLig++;
				var inicio:Sprite = ligacoes[j];
				var end:Sprite = inicioLigacoes[inicio];
				
				var tipoIni:String = Molecula(inicio.parent).getTipoLigacao(inicio);
				var tipoFim:String = Molecula(end.parent).getTipoLigacao(end);
				
				if (tipoIni == tipoFim) {
					if (tipoIni != Molecula.TIPO_INDEFINIDO) {
						if (inicio is MarcacaoCovalente && tipoIni == Molecula.TIPO_COVALENTE) {
							acertosLig++;
						}else if (inicio is MarcacaoPonte && tipoIni == Molecula.TIPO_PONTE) {
							acertosLig++;
						}else {
							spriteLigacoes[j].filters = [erroFilterLig];
							errorFilterOn = true;
						}
					}else {
						spriteLigacoes[j].filters = [erroFilterLig];
						errorFilterOn = true;
					}
				}
			}
			
			var scoreLigacoes:int = Math.round(acertosLig / totalLig * 100);
			
			//score = Math.round((acertosLig + acertosMol) / (totalLig + totalMol)* 100);
			score = Math.round((acertosLig + acertosMol) / (totalLig + totalMol) * 50);
			
			var quantidadesMinimasAtingidas:Boolean = atingiuQuantidades(qtd);
			
			var estruturaCorreta:Boolean = false;
			if (scoreMoleculas > 99 && quantidadesMinimasAtingidas){
				estruturaCorreta = avaliaEstrutura();
				if (estruturaCorreta) score += 50;
			}
			
			var feedBack:String = "Sua pontuação foi de " + score + "%.";
			
			if (scoreMoleculas < 99) {
				if (!quantidadesMinimasAtingidas) feedBack += "\nA quantidade mínima de elementos não foi atingida.";
				feedBack += "\nA estrutura do DNA contém erros.";
				feedBack += "\nAs moléculas com ligações incorretas estão destacadas em vermelho.";
			}
			else {
				if (quantidadesMinimasAtingidas) {
					if (estruturaCorreta) feedBack += "\nA estrutura do DNA está correta.";
					else feedBack += "\nA estrutura do DNA contém erros.";
				}else{
					feedBack += "\nA quantidade mínima de elementos não foi atingida.";
					feedBack += "\nA estrutura do DNA contém erros.";
				}
				feedBack += "\nAs ligações entre as moléculas estão corretas.";
			}
			
			if (scoreLigacoes < 99) feedBack += "\nAs ligações definidas incorretamente, ou indefinidas, estão destacadas em vermelho.";
			else feedBack += "\nOs tipos das ligações foram definidos corretamente.";
			
			//if (estruturaCorreta) feedBack.concat("\nA estrutura do DNA está correta.");
			//else feedBack.concat("\nA estrutura do DNA não está correta.");
			
			feedbackScreen.setText(feedBack);
		}
		
		private function atingiuQuantidades(qtd:Dictionary):Boolean
		{
			var ret:Boolean = true;
			
			if (qtd["fosfato"] < minFosfato) ret = false;
			if (qtd["basePirimidica"] < minPirimidica) ret = false;
			if (qtd["basePurica"] < minPurica) ret = false;
			if (qtd["pentose"] < minPentose) ret = false;
			
			return ret;
		}
		
		private function avaliaEstrutura():Boolean 
		{
			var listaEsquerda:Vector.<Molecula> = new Vector.<Molecula>();
			var listaDireita:Vector.<Molecula> = new Vector.<Molecula>();
			
			for each (var item:Molecula in moleculas) 
			{
				if (item.tipo == "fosfato") {
					if (item.scaleX > 0) {
						if(item.temLigacao()) listaEsquerda.push(item);
					}else {
						if(item.temLigacao()) listaDireita.push(item);
					}
				}else if (item.tipo == "pentose") {
					if (item.rotation != 0) {
						if(item.temLigacao()) listaDireita.push(item);
					}else {
						if(item.temLigacao()) listaEsquerda.push(item);
					}
				}
			}
			
			var esqOk:Boolean = analisaLista(listaEsquerda);
			var dirOk:Boolean = analisaLista(listaDireita, true);
			
			//trace(esqOk, dirOk);
			
			return (esqOk && dirOk);
		}
		
		private function analisaLista(lista:Vector.<Molecula>, inverso:Boolean = false ):Boolean 
		{
			var listaAuxF:Vector.<Molecula> = new Vector.<Molecula>();
			var listaAuxP:Vector.<Molecula> = new Vector.<Molecula>();
			var inicio:Molecula;
			
			var mol:Molecula;
			for (var i:int = lista.length - 1; i >= 0 ; i--) 
			{
				mol = lista[i];
				if (mol is Fosfato) listaAuxF.push(mol);
				else listaAuxP.push(mol);
			}
			
			organizaListaDecrescente(listaAuxF);
			organizaListaDecrescente(listaAuxP);
			
			if (listaAuxF[0].conexaoPtInterno(listaAuxF[0].a) == null) {
				inicio = listaAuxF[0];
				listaAuxF.splice(listaAuxF.indexOf(inicio), 1);
			}else if ((inverso ? listaAuxP[0].conexaoPtInterno(listaAuxP[0].b) : listaAuxP[0].conexaoPtInterno(listaAuxP[0].a)) == null) {
				inicio = listaAuxP[0];
				listaAuxP.splice(listaAuxP.indexOf(inicio), 1);
			}else {
				throw new Error("Lista sem cabeça.");
			}
			
			var proximo:Molecula;
			if (inverso) {
				if (inicio.tipo == "fosfato") proximo = (inicio.conexaoPtInterno(inicio.b) != null ? Molecula(inicio.conexaoPtInterno(inicio.b).parent) : null);
				else proximo = (inicio.conexaoPtInterno(inicio.a) != null ? Molecula(inicio.conexaoPtInterno(inicio.a).parent) : null);
			}else{
				proximo = (inicio.conexaoPtInterno(inicio.b) != null ? Molecula(inicio.conexaoPtInterno(inicio.b).parent) : null);
			}
			
			while (proximo != null) {
				if (listaAuxF.indexOf(proximo) >= 0) {
					listaAuxF.splice(listaAuxF.indexOf(proximo), 1);
				}else {
					listaAuxP.splice(listaAuxP.indexOf(proximo), 1);
				}
				if (inverso) {
					if (proximo.tipo == "fosfato") proximo = (proximo.conexaoPtInterno(proximo.b) != null ? Molecula(proximo.conexaoPtInterno(proximo.b).parent) : null);
					else proximo = (proximo.conexaoPtInterno(proximo.a) != null ? Molecula(proximo.conexaoPtInterno(proximo.a).parent) : null);
				}else{
					proximo = (proximo.conexaoPtInterno(proximo.b) != null ? Molecula(proximo.conexaoPtInterno(proximo.b).parent) : null);
				}
			}
			
			if (listaAuxF.length > 0 || listaAuxP.length > 0) {
				//Os elementos não estão todos ligados.
				return false;
			}
			
			return true;
		}
		
		private function organizaListaDecrescente(lista:Vector.<Molecula>):void
		{
			for (var j:int = 1; j < lista.length; j++) 
			{
				for (var k:int = j; k > 0; k--) 
				{
					if (lista[k].y < lista[k - 1].y) {
						var aux:Molecula = lista[k-1];
						lista[k-1] = lista[k];
						lista[k] = aux;
					}
				}
			}
		}
		
		private function analisaPentose(mol:Molecula):Boolean
		{
			var pentoseA:Sprite = mol.a;
			var pentoseB:Sprite = mol.b;
			var pentoseC:Sprite = mol.c;
			
			var ligA:Sprite = pegaLigacao(pentoseA);
			var ligB:Sprite = pegaLigacao(pentoseB);
			var ligC:Sprite = pegaLigacao(pentoseC);
			
			if (ligA != null && ligB != null) {
				//Se ambos estiverem ligados em uma mesma molécula (erro)
				if (ligA.parent != ligB.parent) {
					if (Molecula(ligA.parent).tipo != "fosfato") {
						return false;
					}
					if (Molecula(ligB.parent).tipo != "fosfato") {
						return false;
					}
				}else {
					return false;
				}
			}else if (ligA != null) {
				if (Molecula(ligA.parent).tipo != "fosfato") {
					return false;
				}
			}else if (ligB != null) {
				if (Molecula(ligB.parent).tipo != "fosfato") {
					return false;
				}
			}
			
			if (ligC != null) {
				//trace(ligC.name);
				if (Molecula(ligC.parent).tipo != "basePirimidica" && Molecula(ligC.parent).tipo != "basePurica") {
					return false;
				}else if(Molecula(ligC.parent).tipo == "basePirimidica"){
					if (ligC.name == "bp4") {
						if ((Molecula(ligC.parent).scaleX < 0 && Molecula(ligC.parent).rotation == 0 && mol.scaleX > 0 && mol.rotation == 0) ||
							(Molecula(ligC.parent).scaleX > 0 && Molecula(ligC.parent).rotation == 0 && mol.scaleX > 0 && Math.abs(mol.rotation + 144) < 1)){
						}else {
							return false;
						}
					}else {
						return false;
					}
				}else {
					if (ligC.name == "bp4") {
						if ((Molecula(ligC.parent).scaleX > 0 && Molecula(ligC.parent).rotation == 0 && mol.scaleX > 0 && mol.rotation == 0) ||
							(Molecula(ligC.parent).scaleX < 0 && Molecula(ligC.parent).rotation == 0 && mol.scaleX > 0 && Math.abs(mol.rotation + 144) < 1)){
						}else {
							return false;
						}
					}else {
						return false;
					}
				}
			}
			
			return true;
		}
		
		private function analisaBase(mol:Molecula):Boolean 
		{
			var baseA:Sprite = mol.bp1;
			var baseB:Sprite = mol.bp2;
			var baseC:Sprite = mol.bp3;
			var baseD:Sprite = mol.bp4;
			
			var ligA:Sprite = pegaLigacao(baseA);
			var ligB:Sprite = pegaLigacao(baseB);
			var ligC:Sprite = pegaLigacao(baseC);
			var ligD:Sprite = pegaLigacao(baseD);
			
			if (ligA != null && ligB != null && ligC != null) {
				if (ligA.parent != ligB.parent || ligA.parent != ligC.parent || ligB.parent != ligC.parent) {
					return false;
				}
			}else if (ligA != null || ligB != null || ligC != null) {
				return false;
			}
			
			if (ligD != null) {
				if (Molecula(ligD.parent).tipo != "pentose") {
					return false;
				}else if (ligD.name == "c") {
					if (mol.tipo == "basePirimidica") {
						if ((mol.scaleX < 0 && mol.rotation == 0 && Molecula(ligD.parent).scaleX > 0 && Molecula(ligD.parent).rotation == 0) ||
							(mol.scaleX > 0 && mol.rotation == 0 && Molecula(ligD.parent).scaleX > 0 && Math.abs(Molecula(ligD.parent).rotation + 144) < 1)){
						}else {
							return false;
						}
					}else {
						if ((mol.scaleX > 0 && mol.rotation == 0 && Molecula(ligD.parent).scaleX > 0 && Molecula(ligD.parent).rotation == 0) ||
							(mol.scaleX < 0 && mol.rotation == 0 && Molecula(ligD.parent).scaleX > 0 && Math.abs(Molecula(ligD.parent).rotation + 144) < 1)){
						}else {
							return false;
						}
					}
				}else {
					return false;
				}
			}
			
			return true;
		}
		
		private function analisaFosfato(mol:Molecula):Boolean
		{
			var fosfatoA:Sprite = mol.a;
			var fosfatoB:Sprite = mol.b;
			
			var ligA:Sprite = pegaLigacao(fosfatoA);
			var ligB:Sprite = pegaLigacao(fosfatoB);
			
			//as 2 ligações possíveis foram feitas.
			if (ligA != null && ligB != null) {
				//Se ambos estiverem ligados em uma mesma molécula (erro)
				if (ligA.parent != ligB.parent) {
					if (Molecula(ligA.parent).tipo != "pentose") {
						return false;
					}else if (ligA.name != "a" && ligA.name != "b") {
						return false;
					}
					if (Molecula(ligB.parent).tipo != "pentose") {
						return false;
					}else if (ligB.name != "a" && ligB.name != "b") {
						return false;
					}
				}else {
					return false;
				}
			}else if (ligA != null) {
				if (Molecula(ligA.parent).tipo != "pentose") {
					return false;
				}else if (ligA.name != "a" && ligA.name != "b") {
					return false;
				}
			}else if (ligB != null) {
				if (Molecula(ligB.parent).tipo != "pentose") {
					return false;
				}else if (ligB.name != "a" && ligB.name != "b") {
					return false;
				}
			}
			
			return true;
		}
		
		private function pegaLigacao(spr:Sprite):Sprite
		{
			if (inicioLigacoes[spr] != null) {
				return inicioLigacoes[spr];
			}else if (fimLigacoes[spr] != null) {
				return fimLigacoes[spr];
			}
			
			return null;
		}
		
		private function createAnswer():void 
		{
			
		}
		
		private function downMoleculasListener(e:MouseEvent):void 
		{
			removeSelection();
			movingObject = Molecula(e.target);
			layerAtividade.setChildIndex(movingObject, layerAtividade.numChildren - 1);
			//layerAtividade.setChildIndex(spriteLigacoes, layerAtividade.numChildren - 1);
			mouseDiff.x = (mouseX - movingObject.x);// * movingObject.scaleX;
			mouseDiff.y = (mouseY - movingObject.y); // * movingObject.scaleY;
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
		
		private function upMoleculasListener(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, movingMoleculas);
			stage.removeEventListener(MouseEvent.MOUSE_UP, upMoleculasListener);
			
			if (movingObject.y > 530) {
				moleculas.splice(moleculas.indexOf(movingObject), 1);
				layerAtividade.removeChild(movingObject);
				movingObject = null;
				lock(opcoes.hInvert);
				lock(opcoes.vInvert);
				procuraLigacoes();
			}else {
				movingObject.filters = [moleculaFilter];
				
				lock(opcoes.vInvert);
				lock(opcoes.hInvert);
				switch (movingObject.tipo) {
					case "fosfato":
						unlock(opcoes.hInvert);
						break;
					case "basePirimidica":
						unlock(opcoes.hInvert);
						break;
					case "basePurica":
						unlock(opcoes.hInvert);
						break;
					case "pentose":
						unlock(opcoes.vInvert);
						break;
				}
			}
			
			saveStatus();
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
			
			//var vetorDist:Array = 
			getTabela();
			var nElementos:int = getNelementos();
			
			var triple:Array = getMinDist(arrayElementos);
			while (triple[2] <= minDist) 
			{
				if (inicioLigacoes[triple[0]] == null && inicioLigacoes[triple[1]] == null && fimLigacoes[triple[0]] == null && fimLigacoes[triple[1]] == null) {
					ligacoes.push(triple[0]);
					inicioLigacoes[triple[0]] = triple[1];
					fimLigacoes[triple[1]] = triple[0];
					
					Molecula(triple[0].parent).setLigacao(triple[0], triple[1]);
					Molecula(triple[1].parent).setLigacao(triple[1], triple[0]);
				}
				triple = getMinDist(arrayElementos);
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
		
		private function getTabela():void
		{
			var nElementos:int = getNelementos();
			//arrayElementos = new Array();
			arrayElementos.splice(0, arrayElementos.length);
			var auxI:int = 0;
			var auxJ:int = 0;
			arrayElementos[nElementos] = new Array();
			for (var i:int = 0; i < moleculas.length; i++) 
			{
				moleculas[i].resetLigacoes();
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
			
			//return arrayElementos;
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
		
		private function redesenhaSpr(spr:Sprite):void
		{
			spr.graphics.clear();
			var item:Sprite = ligacoes[spriteLigacoes.indexOf(spr)];
			
			var end:Sprite = inicioLigacoes[item];
			var ptSpr1:Point = item.parent.localToGlobal(new Point(item.x, item.y));
			var ptSpr2:Point = end.parent.localToGlobal(new Point(end.x, end.y));
			
			spr.graphics.lineStyle(15, 0xFFFF80, 0);
			spr.graphics.moveTo(ptSpr1.x, ptSpr1.y);
			spr.graphics.lineTo(ptSpr2.x, ptSpr2.y);
			
			var cor:uint
			var tipoIni:String = Molecula(item.parent).getTipoLigacao(item);
			var tipoFim:String = Molecula(end.parent).getTipoLigacao(end);
			
			if (tipoIni == tipoFim) cor = colors[tipoIni];
			else cor = colors[Molecula.TIPO_INDEFINIDO];
			
			if (item is MarcacaoPonte) {
				//spriteLigacoes.graphics.lineStyle(lineTickness, colorPonte);
				//dashTo(spriteLigacoes.graphics, ptSpr1.x, ptSpr1.y, ptSpr2.x, ptSpr2.y, dashLen, dashGap);
				spr.graphics.lineStyle(lineTickness, cor);
				dashTo(spr.graphics, ptSpr1.x, ptSpr1.y, ptSpr2.x, ptSpr2.y, dashLen, dashGap);
			}else {
				//spriteLigacoes.graphics.lineStyle(lineTickness, colorCovalente);
				//spriteLigacoes.graphics.moveTo(ptSpr1.x, ptSpr1.y);
				//spriteLigacoes.graphics.lineTo(ptSpr2.x, ptSpr2.y);
				spr.graphics.lineStyle(lineTickness, cor);
				spr.graphics.moveTo(ptSpr1.x, ptSpr1.y);
				spr.graphics.lineTo(ptSpr2.x, ptSpr2.y);
			}
		}
		
		private var dashLen:Number = 3;
		private var dashGap:Number = 3;
		private function desenhaLigacoes():void 
		{
			//spriteLigacoes.graphics.clear();
			removeSprites();
			var end:Sprite;
			
			//for each (var item:Sprite in ligacoes) 
			for (var i:int = 0; i < ligacoes.length; i++) 
			{
				var item:Sprite = ligacoes[i];
				var spr:Sprite = new Sprite();
				spriteLigacoes.push(spr);
				layerAtividade.addChild(spr);
				spr.buttonMode = true;
				spr.addEventListener(MouseEvent.MOUSE_OVER, overLigacao);
				spr.addEventListener(MouseEvent.CLICK, clickLigacao);
				
				end = inicioLigacoes[item];
				var ptSpr1:Point = item.parent.localToGlobal(new Point(item.x, item.y));
				var ptSpr2:Point = end.parent.localToGlobal(new Point(end.x, end.y));
				
				spr.graphics.lineStyle(15, 0xFFFF80, 0);
				spr.graphics.moveTo(ptSpr1.x, ptSpr1.y);
				spr.graphics.lineTo(ptSpr2.x, ptSpr2.y);
				
				var cor:uint
				var tipoIni:String = Molecula(item.parent).getTipoLigacao(item);
				var tipoFim:String = Molecula(end.parent).getTipoLigacao(end);
				
				if (tipoIni == tipoFim) cor = colors[tipoIni];
				else cor = colors[Molecula.TIPO_INDEFINIDO];
				
				if (item is MarcacaoPonte) {
					//spriteLigacoes.graphics.lineStyle(lineTickness, colorPonte);
					//dashTo(spriteLigacoes.graphics, ptSpr1.x, ptSpr1.y, ptSpr2.x, ptSpr2.y, dashLen, dashGap);
					spr.graphics.lineStyle(lineTickness, cor);
					dashTo(spr.graphics, ptSpr1.x, ptSpr1.y, ptSpr2.x, ptSpr2.y, dashLen, dashGap);
				}else {
					//spriteLigacoes.graphics.lineStyle(lineTickness, colorCovalente);
					//spriteLigacoes.graphics.moveTo(ptSpr1.x, ptSpr1.y);
					//spriteLigacoes.graphics.lineTo(ptSpr2.x, ptSpr2.y);
					spr.graphics.lineStyle(lineTickness, cor);
					spr.graphics.moveTo(ptSpr1.x, ptSpr1.y);
					spr.graphics.lineTo(ptSpr2.x, ptSpr2.y);
				}
			}
		}
		
		private var ligacaoSelecionada:Sprite;
		private var filterLigacao:GlowFilter = new GlowFilter(0x00FF00, 1, 12, 12);
		private function overLigacao(e:MouseEvent):void 
		{
			if (errorFilterOn) return;
			var lig:Sprite = Sprite(e.target);
			if (ligacaoSelecionada != null) {
				if (ligacaoSelecionada == lig) return;
			}
			
			lig.addEventListener(MouseEvent.MOUSE_OUT, outLigacao);
			lig.filters = [filterLigacao];
		}
		
		private function outLigacao(e:MouseEvent):void 
		{
			var lig:Sprite = Sprite(e.target);
			lig.removeEventListener(MouseEvent.MOUSE_OUT, outLigacao);
			lig.filters = [];
		}
		
		private function clickLigacao(e:MouseEvent):void 
		{
			removeSelection();
			ligacaoSelecionada = Sprite(e.target);
			ligacaoSelecionada.filters = [ligacaoFilter];
			ligacaoSelecionada.removeEventListener(MouseEvent.MOUSE_OUT, outLigacao);
			var sprIni:Sprite = ligacoes[spriteLigacoes.indexOf(ligacaoSelecionada)];
			var sprFim:Sprite = inicioLigacoes[sprIni];
			
			var tipoIni:String = Molecula(sprIni.parent).getTipoLigacao(sprIni);
			var tipoFim:String = Molecula(sprFim.parent).getTipoLigacao(sprFim);
			
			if (tipoIni == tipoFim) menuTipoLigacao[tipoIni].selected = true;
			else menuTipoLigacao.indefinido.selected = true;
			
			Actuate.tween(menuTipoLigacao, 0.3, { x:posInicialMenuLigacao } );
		}
		
		private function removeSprites():void 
		{
			for (var i:int = 0; i < spriteLigacoes.length; i++) 
			{
				layerAtividade.removeChild(spriteLigacoes[i]);
				spriteLigacoes[i].removeEventListener(MouseEvent.MOUSE_OVER, overLigacao);
				spriteLigacoes[i].removeEventListener(MouseEvent.CLICK, clickLigacao);
			}
			spriteLigacoes.splice(0, spriteLigacoes.length);
		}
		
		private function saveStatusForRecovery(e:MouseEvent = null):void
		{
			var status:Object = new Object();
			
			status.completed = completed;
			status.score = score;
			status.moleculas = new Object();
			status.moleculas.qtd = moleculas.length;
			
			for (var i:int = 0; i < moleculas.length; i++) 
			{
				var obj:Molecula = moleculas[i];
				status.moleculas[String(i)] = new Object();
				status.moleculas[String(i)].posX = obj.x;
				status.moleculas[String(i)].posY = obj.y;
				status.moleculas[String(i)].rotacao = obj.rotation;
				status.moleculas[String(i)].scaleX = obj.scaleX;
				status.moleculas[String(i)].scaleY = obj.scaleY;
				status.moleculas[String(i)].tipo = obj.tipo;
				status.moleculas[String(i)].tiposLigacao = new Object();
				//for each (var item:Sprite in obj.pontosLigacao) 
				for (var j:int = 0; j < obj.pontosLigacao.length; j++) 
				{
					var item:Sprite = obj.pontosLigacao[j];
					if(obj.tiposPontos[j] != Molecula.TIPO_INDEFINIDO) status.moleculas[String(i)].tiposLigacao[item.name] = obj.tiposPontos[j];
				}
			}
			
			mementoSerialized = JSON.encode(status);
		}
		
		private function recoverStatus(memento:String):void
		{
			var status:Object = JSON.decode(memento);
			
			for (var i:int = 0; i < status.moleculas.qtd; i++) 
			{
				var mol:Molecula = criaObjeto(status.moleculas[String(i)].tipo, status.moleculas[String(i)].posX, status.moleculas[String(i)].posY, status.moleculas[String(i)].rotacao, status.moleculas[String(i)].scaleX, status.moleculas[String(i)].scaleY);
				
				for each (var item:Sprite in mol.pontosLigacao) 
				{
					if(status.moleculas[String(i)].tiposLigacao[item.name]) mol.setTipoLigacao(item, status.moleculas[String(i)].tiposLigacao[item.name]);
				}
			}
			
			if (!connected) {
				completed = status.completed;
				score = status.score;
			}
			
			procuraLigacoes();
		}
		
		override public function reset(e:MouseEvent = null):void
		{
			for each (var item:Molecula in moleculas) 
			{
				layerAtividade.removeChild(item);
			}
			
			moleculas.splice(0, moleculas.length);
			//spriteLigacoes.graphics.clear();
			removeSprites();
			lock(opcoes.hInvert);
			lock(opcoes.vInvert);
			
			if(connected){
				if (completed) return;
			}else {
				if (completed) completed = false;
				score = 0;
			}
			
			//saveStatus();
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
								"Clique e arraste sobre uma molécula para criá-la.",
								"Utilize esses controles para modificar (rotacionar e inverter) as peças.",
								"Posicione as moléculas para montar um segmento de DNA.",
								"São necessárias no mínimo " + minFosfato + " fosfatos, " + minPentose + " pentoses, " + minPirimidica + " bases pirimídicas e " + minPurica + " bases púricas.",
								"Ao movimentar as moléculas serão formadas as ligações (covalente ou ponte de hidrogênio)...",
								"...de acordo com a proximidade entre os elementos que formam a ligação.",
								"Para apagar uma molécula basta arrastá-la para a barra inferior ou pressionar \"delete\" quando ela estiver selecionada.",
								"Clique sobre uma ligação para classificá-la (ligação covalente ou ponte de hidrogênio).",
								"Pressione \"terminei\" para avaliar sua resposta."];
				
				pointsTuto = 	[new Point(560, 550),
								new Point(220 , 550),
								new Point(480 , 550),
								new Point(180 , 180),
								new Point(200 , 200),
								new Point(220 , 220),
								new Point(240 , 240),
								new Point(180 , 260),
								new Point(220 , 260),
								new Point(finaliza.x, finaliza.y - finaliza.height / 2)];
								
				tutoBaloonPos = [[CaixaTexto.BOTTON, CaixaTexto.LAST],
								[CaixaTexto.BOTTON, CaixaTexto.FIRST],
								[CaixaTexto.BOTTON, CaixaTexto.LAST],
								["", ""],
								["", ""],
								["", ""],
								["", ""],
								["", ""],
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