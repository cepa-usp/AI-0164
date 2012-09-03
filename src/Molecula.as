package  
{
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
		private var pontosLigacao:Vector.<Sprite> = new Vector.<Sprite>();
		private var ligacoesAtuais:Dictionary = new Dictionary();
		
		public function Molecula() 
		{
			this.buttonMode = true;
		}
		
		public function get posicoesPontosLigacao():Vector.<Point>
		{
			var vec:Vector.<Point> = new Vector.<Point>();
			for (var i:int = 0; i < pontosLigacao.length; i++) 
			{
				vec.push(new Point(pontosLigacao[i].x + this.x, pontosLigacao[i].y + this.y));
			}
			
			return vec;
		}
		
		public function setLigacao(pontoExterno:Sprite, pontoInterno:Sprite):void
		{
			ligacoesAtuais[pontoInterno] = pontoExterno;
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