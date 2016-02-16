package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.PNGenerators

final class VNGenerators {
	def static List<Generator> generators() {
		(2 .. Constants.MAX_ARITY).map[generator(it)].toList
	}

	private def static Generator generator(int arity) {
		new ClassGenerator {
			override className() { Constants.V + arity }

			override sourceCode() { '''
				package «Constants.COLLECTION»;

				import java.io.Serializable;
				import java.util.ArrayList;
				import java.util.Iterator;
				import java.util.HashSet;
				import java.util.stream.Stream;
				import java.util.stream.StreamSupport;

				import «Constants.INDEXED»;
				import «Constants.P»;
				«FOR arity : 3 .. Constants.MAX_ARITY»
					import «Constants.P»«arity»;
				«ENDFOR»
				import «Constants.PRECISE_SIZE»;
				import «Constants.SIZED»;
				import «Constants.F»;
				«FOR arity : 2 .. Constants.MAX_ARITY»
					import «Constants.F»«arity»;
				«ENDFOR»

				import static java.util.Arrays.asList;
				import static java.util.Objects.requireNonNull;
				import static «Constants.P».p;
				«IF arity > 2»
					import static «Constants.P»«arity».p«arity»;
				«ENDIF»
				import static «Constants.PRECISE_SIZE».preciseSize;

				public final class V«arity»<A> implements Iterable<A>, Sized, Indexed<A>, Serializable {
					private static final PreciseSize SIZE = preciseSize(«arity»);

					private final A «(1 .. arity).map["a" + it].join(", ")»;

					private V«arity»(«(1 .. arity).map["final A a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							this.a«i» = a«i»;
						«ENDFOR»
					}

					@Override
					public PreciseSize size() {
						return SIZE;
					}

					«FOR i : 1 .. arity»
						public A get«i»() {
							return a«i»;
						}

					«ENDFOR»
					@Override
					public A get(final int index) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: return a«i»;
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					«FOR i : 1 .. arity»
						public V«arity»<A> set«i»(final A a«i») {
							return new V«arity»<>(«(1 .. arity).map[if (it == i) '''requireNonNull(a«i»)''' else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public V«arity»<A> set(final int index, final A value) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: return new V«arity»<>(«(1 .. arity).map[if (it == i) '''requireNonNull(value)''' else "a" + it].join(", ")»);
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					«FOR i : 1 .. arity»
						public V«arity»<A> update«i»(final F<A, A> f) {
							final A a = f.apply(a«i»);
							return new V«arity»<>(«(1 .. arity).map[if (it == i) "requireNonNull(a)" else "a" + it].join(", ")»);
						}

					«ENDFOR»
					public V«arity»<A> update(final int index, final F<A, A> f) {
						switch (index) {
							«FOR i : 1 .. arity»
								case «i-1»: {
									final A a = f.apply(a«i»);
									return new V«arity»<>(«(1 .. arity).map[if (it == i) "requireNonNull(a)" else "a" + it].join(", ")»);
								}
							«ENDFOR»
							default: throw new IndexOutOfBoundsException(Integer.toString(index));
						}
					}

					public <B> B match(final F«arity»<«(1 .. arity).map["A, "].join»B> f) {
						final B b = f.apply(«(1 .. arity).map["a" + it].join(", ")»);
						return requireNonNull(b);
					}

					public <B> V«arity»<B> map(final F<A, B> f) {
						return v«arity»(«(1 .. arity).map["f.apply(a" + it + ")"].join(", ")»);
					}

					«IF arity == 2»
						public V2<A> flip() {
							return new V2<>(a2, a1);
						}

					«ENDIF»
					public boolean contains(final A value) {
						requireNonNull(value);
						«FOR i : 1 .. arity»
							if (a«i».equals(value)) {
								return true;
							}
						«ENDFOR»
						return false;
					}

					public «PNGenerators.shortName(arity)»<«(1 .. arity).map["A"].join(", ")»> toP«if (arity == 2) "" else arity»() {
						return «PNGenerators.shortName(arity).toLowerCase»(«(1 .. arity).map["a" + it].join(", ")»);
					}

					public ArrayList<A> toArrayList() {
						final ArrayList<A> result = new ArrayList<>(«arity»);
						«FOR index : 1 .. arity»
							result.add(a«index»);
						«ENDFOR»
						return result;
					}

					public HashSet<A> toHashSet() {
						final HashSet<A> result = new HashSet<>(«Math.ceil(arity / 0.75) as int»);
						«FOR index : 1 .. arity»
							result.add(a«index»);
						«ENDFOR»
						return result;
					}

					@Override
					public Iterator<A> iterator() {
						return asList(«(1 .. arity).map["a" + it].join(", ")»).iterator();
					}

					«stream»

					«parallelStream»

					«zip(false)»

					«zipWith(false)»

					public V«arity»<P<A, Integer>> zipWithIndex() {
						return new V«arity»<>(«(1 .. arity).map["p(a" + it + ", " + (it-1) + ")"].join(", ")»);
					}

					@Override
					public String toString() {
						return "V«arity»(" + «(1 .. arity).map["a" + it].join(''' + ", " + ''')» + ")";
					}

					public static <A> V«arity»<A> v«arity»(«(1 .. arity).map["final A a" + it].join(", ")») {
						«FOR i : 1 .. arity»
							requireNonNull(a«i»);
						«ENDFOR»
						return new V«arity»<>(«(1 .. arity).map["a" + it].join(", ")»);
					}

					public static <A> V«arity»<A> p«if (arity == 2) "" else arity»ToV«arity»(final «PNGenerators.shortName(arity)»<«(1 .. arity).map["A"].join(", ")»> p«arity») {
						return new V«arity»<>(«(1 .. arity).map["p" + arity + ".get" + it + "()"].join(", ")»);
					}

					«zipN(false)»
					«zipWithN(false)[i | '''
						«FOR j : 1 .. arity»
							final B b«j» = requireNonNull(f.apply(«(1 .. i).map['''v«it».a«j»'''].join(", ")»));
						«ENDFOR»
						return new V«arity»<>(«(1 .. arity).map["b" + it].join(", ")»);
					''']»
					«cast(#["A"], #[], #["A"])»
				}
			''' }
		}
	}
}