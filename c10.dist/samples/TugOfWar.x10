
import x10.util.Random;
import x10.util.List;
import c10.lang.*;
import c10.lang.probability.*;
import c10.lang.Rail;
import c10.lang.Double;
import c10.lang.Int;
import c10.lang.Boolean;
import c10.lang.Reducible;
import c10.runtime.agent.*;
import c10.compiler.agent;
import c10.runtime.herbrand.Vat;
import c10.util.SamplingDriver;
import c10.util.SamplingMHDriver;

public class TugOfWar extends Vat.BasicInitCall[XInt] {
	static val T = Boolean.TRUE, F = Boolean.FALSE;
	static val Plus = Reducible.IntSumReducer();
	static type PV=ProbabilisticValue[XBoolean];
	static struct Person(name:String){
		val strength  =  s();
		static def s():Int= { // determined statically
			val x = new Int();
			tell(x ~ new Gaussian(100n, 20n));
			x
		};
		def lazy():Boolean = { // determined per call
			val x = new Boolean();
			tell(x ~ new PV([T~0.9,F~0.1]));
			x 
		}
		def pulling():Int = {
			val x=new Int(this+".pulling");
			val l = lazy();
			ask( (l~true) -> (x~(strength/2n)) );
			ask( (l~false) -> (x~strength) );
			x
		}
		public def toString()="Person<"+name+ " " + strength + ">";
	}
	static class Team extends Atom[XRail[Person]] {
		def this(){super();}
		def this(t:XRail[Person]){super(t);}
		def totalPulling() = Rail.reduce(Rail.map(this(), (p:Person)=>p.pulling()), Plus);
		
		protected def equalsCheck(a:XRail[Person], b:XRail[Person]):XBoolean {
			if (a.range() != b.range()) return false;
			for (i in a.range()) if (! a(i).equals(b(i))) return false;
			return true;
		}
		
		def winner(other:Team) = { 
			val x = new Team();
			val t = totalPulling(), ot=other.totalPulling();
			ask(t -> (ot -> (()=> {tell (x~ (t()>ot() ? this:other));})));
			x
		}
		public def toString()="Team<" + this()+">";
	}
	static def results(Bob:Person) {
		val Mark=Person("mark"), Tom=Person("tom"), Sam=Person("sam"), 
		    Fred=Person("fred"), Jon=Person("jon"), Jim=Person("jim");
		val BM = new Team([Bob, Mark]), TS = new Team([Tom,Sam]), 
		    BF = new Team([Bob,Fred]), JJ = new Team([Jon,Jim]); 
		    tell (BM.winner(TS) ~ BM);
		    tell (BF.winner(JJ) ~ BF);
	}
	public def this() {super((i:XInt)=>new Int("r"+i));}
	public def varName()="Bob.strength";
	public def getAgent() =  {
		val Bob = Person("bob");
		new Now(()=>{
			tell(p ~ Bob.strength); // result variable
			results(Bob); 
		})};
	@agent public static def main(args: XRail[String]) {
		new SamplingDriver[XInt](10000).run(args, ()=>new TugOfWar());
	}
}