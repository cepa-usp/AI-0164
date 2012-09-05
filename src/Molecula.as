package  
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Molecula extends MovieClip
	{
		public static const TIPO_INDEFINIDO:String = "indefinido";
		public static const TIPO_COVALENTE:String = "covalente";
		public static const TIPO_PONTE:String = "ponteHidrogenio";
		
		private var _pontosLigacao:Vector.<Sprite> = new Vector.<Sprite>();
		private var _tiposPontos:Vector.<String> = new Vector.<String>();
		private var ligacoesAtuais:Dictionary = new Dictionary();
		public var tipo:String;
		
		public function Molecula() 
		{
			this.buttonMode = true;
			this.mouseChildren = false;
			pegaLigacoes();
		}
		
		private function pegaLigacoes():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is MarcacaoCovalente || child is MarcacaoPonte) {
					_pontosLigacao.push(child);
					_tiposPontos.push(TIPO_INDEFINIDO);
				}
			}
		}
		
		/*public function get posicoesPontosLigacao():Vector.<Point>
		{
			var vec:Vector.<Point> = new Vector.<Point>();
			for (var i:int = 0; i < pontosLigacao.length; i++) 
			{
				if(temConexao(pontosLigacao[i])) vec.push(new Point(pontosLigacao[i].x + this.x, pontosLigacao[i].y + this.y));
			}
			
			return vec;
		}*/
		
		public function get pontosLigacao():Vector.<Sprite> 
		{
			return _pontosLigacao;
		}
		
		public function get tiposPontos():Vector.<String> 
		{
			return _tiposPontos;
		}
		
		public function setLigacao(pontoInterno:Sprite, pontoExterno:Sprite):void
		{
			ligacoesAtuais[pontoInterno] = pontoExterno;
		}
		
		public function temLigacao():Boolean
		{
			var ret:Boolean = false;
			for each (var item:Sprite in pontosLigacao) 
			{
				if (ligacoesAtuais[item] != null) ret = true;
			}
			return ret;
		}
		
		public function resetLigacoes():void
		{
			ligacoesAtuais = new Dictionary();
		}
		
		public function removeLigacao(pontoInterno:Sprite):void
		{
			ligacoesAtuais[pontoInterno] = null;
		}
		
		public function getPosicaoPontoLigacao(ponto:Sprite):Point
		{
			var index:int = pontosLigacao.indexOf(ponto);
			if (index >= 0) return new Point(pontosLigacao[index].x + this.x, pontosLigacao[index].y + this.y);
			else return null;
		}
		
		public function temConexao(ponto:Sprite):Boolean
		{
			if (ligacoesAtuais[ponto] != null) return true;
			else return false;
		}
		
		public function estaConectado(ponto:Sprite):Boolean
		{
			for each (var item:Sprite in pontosLigacao) 
			{
				if (ligacoesAtuais[item] == ponto) return true;
			}
			return false;
		}
		
		public function conexaoPtInterno(pontoInterno:Sprite):Sprite
		{
			return ligacoesAtuais[pontoInterno];
		}
		
		public function conexaoPtExterno(pontoExterno:Sprite):Sprite
		{
			for each (var item:Sprite in pontosLigacao) 
			{
				if (ligacoesAtuais[item] == pontoExterno) return item;
			}
			return null;
		}
		
	}

}