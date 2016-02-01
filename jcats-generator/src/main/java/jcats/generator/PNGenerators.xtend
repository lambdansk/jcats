package jcats.generator

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator

final class PNGenerators {
	def static List<Generator> generators() {
		(2 .. Constants.MAX_ARITY).map[generator(it)].toList
	}

	private def static Generator generator(int arity) {
		new ClassGenerator {
			override className() { Constants.P + arity }

			override sourceCode() { '''
				package «Constants.JCATS»;

				import java.io.Serializable;
				import «Constants.F»;
				import «Constants.F»«arity»;

				import static java.util.Objects.requireNonNull;

				public final class P«arity»<«(1 .. arity).map["A" + it].join(", ")»> implements Serializable {
					«FOR i : 1 .. arity»
						private final A«i» a«i»;
					«ENDFOR»

					private P«arity»(«(1 .. arity).map["final A" + it + " a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							this.a«i» = a«i»;
						«ENDFOR»
					}

					«FOR i : 1 .. arity»
						public A«i» get«i»() {
							return a«i»;
						}

					«ENDFOR»
					«FOR i : 1 .. arity»
						public <B> P«arity»<«(1 .. arity).map[if (it == i) "B" else "A" + it].join(", ")»> set«i»(final B value) {
							return new P«arity»<>(«(1 .. arity).map[if (it == i) '''requireNonNull(value)''' else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public <B> B match(final F«arity»<«(1 .. arity).map["A" + it + ", "].join»B> f) {
						final B b = f.apply(«(1 .. arity).map["a" + it].join(", ")»);
						return requireNonNull(b);
					}

					«FOR i : 1 .. arity»
						public <B> P«arity»<«(1 .. arity).map[if (it == i) "B" else "A" + it].join(", ")»> map«i»(final F<A«i», B> f) {
							final B b = f.apply(a«i»);
							return new P«arity»<>(«(1 .. arity).map[if (it == i) "requireNonNull(b)" else "a" + it].join(", ")»);
						}

					«ENDFOR»
					«IF arity == 2»
						public P2<A2, A1> flip() {
							return new P2<>(a2, a1);
						}

						public <B1, B2> P2<B1, B2> biMap(final F<A1, B1> f1, final F<A2, B2> f2) {
							return p2(f1.apply(a1), f2.apply(a2));
						}

					«ENDIF»
					public static <«(1 .. arity).map["A" + it].join(", ")»> P«arity»<«(1 .. arity).map["A" + it].join(", ")»> p«arity»(«(1 .. arity).map["final A" + it + " a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							requireNonNull(a«i»);
						«ENDFOR»
						return new P«arity»<>(«(1 .. arity).map["a" + it].join(", ")»);
					}

					@Override
					public String toString() {
						return "(" + «(1 .. arity).map["a" + it].join(''' + ", " + ''')» + ")";
					}

					«cast((1 .. arity).map["A" + it], #[], (1 .. arity).map["A" + it])»
				}
			''' }		
		}
	}
}