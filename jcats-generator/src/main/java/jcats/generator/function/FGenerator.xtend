package jcats.generator.function

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class FGenerator implements InterfaceGenerator {
	val Type from
	val Type to

	def static List<Generator> generators() {
		Type.values.toList.map[from | Type.values.toList.map[to | new FGenerator(from, to) as Generator]].flatten.toList
	}

	override className() {
		Constants.FUNCTION + "." + shortName
	}

	def shortName() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"F"
		} else if (from == Type.OBJECT) {
			to.typeName + "F"
		} else {
			from.typeName + to.typeName + "F"
		}
	}

	def typeParams() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"<A, B>"
		} else if (from == Type.OBJECT || to == Type.OBJECT) {
			"<A>"
		} else {
			""
		}
	}

	def fromName() {
		if (from == Type.OBJECT) "A" else from.javaName
	}

	def toName() {
		if (from == Type.OBJECT && to == Type.OBJECT) {
			"B"
		} else if (to == Type.OBJECT) {
			"A"
		} else {
			to.javaName
		}
	}

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		«IF from == Type.OBJECT && to == Type.OBJECT»
			import java.util.function.Function;
		«ELSEIF from != Type.BOOL && to == Type.OBJECT»
			import java.util.function.«from.javaPrefix»Function;
		«ELSEIF from == Type.OBJECT && to != Type.BOOL»
			import java.util.function.To«to.javaPrefix»Function;
		«ELSEIF from == Type.BOOL && to == Type.OBJECT»
			import java.util.function.Function;
		«ELSEIF from == Type.OBJECT && to == Type.BOOL»
			import java.util.function.Predicate;
		«ELSEIF from == to && to != Type.BOOL»
			import java.util.function.«from.javaPrefix»UnaryOperator;
		«ELSEIF from == Type.BOOL && to == Type.BOOL»
			import java.util.function.UnaryOperator;
			import java.util.function.Predicate;
		«ELSEIF to == Type.BOOL»
			import java.util.function.«from.javaPrefix»Predicate;
		«ELSEIF from != Type.BOOL && to != Type.BOOL»
			import java.util.function.«from.javaPrefix»To«to.javaPrefix»Function;
		«ELSEIF from == Type.BOOL»
			import java.util.function.To«to.javaPrefix»Function;
		«ENDIF»

		import static java.util.Objects.requireNonNull;
		import static «Constants.F».id;

		@FunctionalInterface
		public interface «shortName»«typeParams» {
			«toName» apply(final «fromName» value);

			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C> F<A, C> map(final F<B, C> f) {
					requireNonNull(f);
					return a -> {
						requireNonNull(a);
						final B b = requireNonNull(apply(a));
						return requireNonNull(f.apply(b));
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B> «shortName»<B> map(final F<A, B> f) {
					requireNonNull(f);
					return value -> {
						final A a = requireNonNull(apply(value));
						return requireNonNull(f.apply(a));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B> F<A, B> map(final «to.typeName»ObjectF<B> f) {
					requireNonNull(f);
					return a -> {
						requireNonNull(a);
						final «toName» value = apply(a);
						return requireNonNull(f.apply(value));
					};
				}
			«ELSE»
				default <A> «from.typeName»ObjectF<A> map(final «to.typeName»ObjectF<A> f) {
					requireNonNull(f);
					return value -> {
						final «toName» result = apply(value);
						return requireNonNull(f.apply(result));
					};
				}
			«ENDIF»

			«FOR primitive : Type.values.filter[it != Type.OBJECT]»
				«IF from == Type.OBJECT && to == Type.OBJECT»
					default «primitive.typeName»F<A> mapTo«primitive.typeName»(final «primitive.typeName»F<B> f) {
						requireNonNull(f);
						return a -> {
							requireNonNull(a);
							final B b = requireNonNull(apply(a));
							return f.apply(b);
						};
					}
				«ELSEIF to == Type.OBJECT»
					default «from.typeName»«primitive.typeName»F mapTo«primitive.typeName»(final «primitive.typeName»F<A> f) {
						requireNonNull(f);
						return value -> {
							final A a = requireNonNull(apply(value));
							return f.apply(a);
						};
					}
				«ELSEIF from == Type.OBJECT»
					default «primitive.typeName»F<A> mapTo«primitive.typeName»(final «to.typeName»«primitive.typeName»F f) {
						requireNonNull(f);
						return a -> {
							requireNonNull(a);
							final «toName» value = apply(a);
							return f.apply(value);
						};
					}
				«ELSE»
					default «from.typeName»«primitive.typeName»F mapTo«primitive.typeName»(final «to.typeName»«primitive.typeName»F f) {
						requireNonNull(f);
						return value -> {
							final «toName» result = apply(value);
							return f.apply(result);
						};
					}
				«ENDIF»

			«ENDFOR»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C> F<C, B> contraMap(final F<C, A> f) {
					requireNonNull(f);
					return c -> {
						requireNonNull(c);
						final A a = requireNonNull(f.apply(c));
						return requireNonNull(apply(a));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B> «to.typeName»F<B> contraMap(final F<B, A> f) {
					requireNonNull(f);
					return b -> {
						requireNonNull(b);
						final A a = requireNonNull(f.apply(b));
						return apply(a);
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B> F<B, A> contraMap(final «from.typeName»F<B> f) {
					requireNonNull(f);
					return b -> {
						requireNonNull(b);
						final «fromName» value = f.apply(b);
						return requireNonNull(apply(value));
					};
				}
			«ELSE»
				default <A> «to.typeName»F<A> contraMap(final «from.typeName»F<A> f) {
					requireNonNull(f);
					return a -> {
						requireNonNull(a);
						final «fromName» value = f.apply(a);
						return apply(value);
					};
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C, D> F<C, D> diMap(final F<C, A> f, final F<B, D> g) {
					requireNonNull(f);
					requireNonNull(g);
					return c -> {
						requireNonNull(c);
						final A a = requireNonNull(f.apply(c));
						final B b = requireNonNull(apply(a));
						return requireNonNull(g.apply(b));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B, C> F<B, C> diMap(final F<B, A> f, final «to.typeName»ObjectF<C> g) {
					requireNonNull(f);
					requireNonNull(g);
					return b -> {
						requireNonNull(b);
						final A a = requireNonNull(f.apply(b));
						final «toName» value = apply(a);
						return requireNonNull(g.apply(value));
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B, C> F<B, C> diMap(final «from.typeName»F<B> f, final F<A, C> g) {
					requireNonNull(f);
					requireNonNull(g);
					return b -> {
						requireNonNull(b);
						final «fromName» value = f.apply(b);
						final A a = requireNonNull(apply(value));
						return requireNonNull(g.apply(a));
					};
				}
			«ELSE»
				default <A, B> F<A, B> diMap(final «from.typeName»F<A> f, final «to.typeName»ObjectF<B> g) {
					requireNonNull(f);
					requireNonNull(g);
					return a -> {
						requireNonNull(a);
						final «fromName» value = f.apply(a);
						final «toName» result = apply(value);
						return requireNonNull(g.apply(result));
					};
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				default <C> F<A, C> flatMap(final F<B, F<A, C>> f) {
					requireNonNull(f);
					return a -> {
						requireNonNull(a);
						final B b = requireNonNull(apply(a));
						return requireNonNull(f.apply(b).apply(a));
					};
				}
			«ELSEIF to == Type.OBJECT»
				default <B> «shortName»<B> flatMap(final F<A, «shortName»<B>> f) {
					requireNonNull(f);
					return value -> {
						final A a = requireNonNull(apply(value));
						return requireNonNull(f.apply(a).apply(value));
					};
				}
			«ELSEIF from == Type.OBJECT»
				default <B> F<A, B> flatMap(final «to.typeName»ObjectF<F<A, B>> f) {
					requireNonNull(f);
					return a -> {
						requireNonNull(a);
						final «toName» value = apply(a);
						return requireNonNull(f.apply(value).apply(a));
					};
				}
			«ELSE»
				default <A> «from.typeName»ObjectF<A> flatMap(final «to.typeName»ObjectF<«from.typeName»ObjectF<A>> f) {
					requireNonNull(f);
					return value -> {
						final «toName» result = apply(value);
						return requireNonNull(f.apply(result).apply(value));
					};
				}
			«ENDIF»

			«IF from != Type.OBJECT && to == Type.OBJECT»
				default F<«from.boxedName», A> toF() {
					return value -> {
						final A result = apply(value);
						return requireNonNull(result);
					};
				}

			«ELSEIF from == Type.OBJECT && to != Type.OBJECT»
				default F<A, «to.boxedName»> toF() {
					return value -> apply(requireNonNull(value));
				}

			«ELSEIF from != Type.OBJECT && to != Type.OBJECT»
				default «from.typeName»ObjectF<«to.boxedName»> to«from.typeName»ObjectF() {
					return this::apply;
				}

				default «to.typeName»F<«from.boxedName»> to«to.typeName»F() {
					return this::apply;
				}

				default F<«from.boxedName», «to.boxedName»> toF() {
					return this::apply;
				}

			«ENDIF»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				default Function<A, B> toFunction() {
					return a -> {
						requireNonNull(a);
						return requireNonNull(apply(a));
					};
				}
			«ELSEIF from != Type.BOOL && to == Type.OBJECT»
				default «from.javaPrefix»Function<A> toFunction() {
					return value -> requireNonNull(apply(value));
				}
			«ELSEIF from == Type.BOOL && to == Type.OBJECT»
				default Function<Boolean, A> toFunction() {
					return value -> {
						requireNonNull(value);
						return requireNonNull(apply(value));
					};
				}
			«ELSEIF from == Type.OBJECT && to != Type.BOOL»
				default To«to.javaPrefix»Function<A> toFunction() {
					return a -> apply(requireNonNull(a));
				}
			«ELSEIF from == Type.OBJECT && to == Type.BOOL»
				default Predicate<A> toPredicate() {
					return a -> {
						requireNonNull(a);
						return apply(a);
					};
				}
			«ELSEIF from == to && to != Type.BOOL»
				default «from.javaPrefix»UnaryOperator toOperator() {
					return this::apply;
				}
			«ELSEIF from == Type.BOOL && to == Type.BOOL»
				default UnaryOperator<Boolean> toOperator() {
					return this::apply;
				}

				default Predicate<Boolean> toPredicate() {
					return this::apply;
				}
			«ELSEIF to == Type.BOOL»
				default «from.javaPrefix»Predicate toPredicate() {
					return this::apply;
				}
			«ELSEIF from != Type.BOOL && to != Type.BOOL»
				default «from.javaPrefix»To«to.javaPrefix»Function toFunction() {
					return this::apply;
				}
			«ELSEIF from == Type.BOOL»
				default To«to.javaPrefix»Function<Boolean> toFunction() {
					return this::apply;
				}
			«ENDIF»

			«IF from == Type.OBJECT»
				default Eff<A> toEff() {
					return a -> apply(requireNonNull(a));
				}

			«ELSE»
				default «from.typeName»Eff toEff() {
					return this::apply;
				}

			«ENDIF»
			«IF from == to»
				«IF from == Type.OBJECT»
					static <A> F<A, A> id() {
						return (F<A, A>) Fs.ID;
					}

				«ELSE»
					static «shortName» id() {
						return Fs.«from.typeName.toUpperCase»_ID;
					}

				«ENDIF»
			«ENDIF»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				static <A, B> F<A, B> constant(final B b) {
					requireNonNull(b);
					return a -> {
						requireNonNull(a);
						return b;
					};
				}
			«ELSEIF to == Type.OBJECT»
				static <A> «shortName»<A> constant(final A a) {
					requireNonNull(a);
					return __ -> a;
				}
			«ELSEIF from == Type.OBJECT»
				static <A> «shortName»<A> constant(final «toName» value) {
					return a -> {
						requireNonNull(a);
						return value;
					};
				}
			«ELSE»
				static «shortName» constant(final «toName» value) {
					return __ -> value;
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				static <A, B> F<A, B> fromF0(final F0<B> b) {
					return b.toConstF();
				}
			«ELSEIF from == Type.OBJECT»
				static <A> «shortName»<A> from«to.typeName»F0(final «to.typeName»F0 f) {
					return f.toConstF();
				}
			«ELSEIF to == Type.OBJECT»
				static <A> «shortName»<A> fromF0(final F0<A> a) {
					return a.toConst«shortName»();
				}
			«ELSE»
				static «shortName» from«to.typeName»F0(final «to.typeName»F0 f) {
					return f.toConst«shortName»();
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				«joinMultiple(#["A"], "B")»
			«ELSEIF to == Type.OBJECT»
				«join»
			«ELSEIF from == Type.OBJECT»
				static <A> «shortName»<A> join(final F<A, «shortName»<A>> f) {
					requireNonNull(f);
					return a -> {
						requireNonNull(a);
						return f.apply(a).apply(a);
					};
				}
			«ELSE»
				static «shortName» join(final «from.typeName»ObjectF<«shortName»> f) {
					requireNonNull(f);
					return value -> f.apply(value).apply(value);
				}
			«ENDIF»

			«IF from == Type.OBJECT && to == Type.OBJECT»
				static <A, B> F<A, B> fromFunction(final Function<A, B> f) {
					requireNonNull(f);
					return a -> {
						requireNonNull(a);
						return requireNonNull(f.apply(a));
					};
				}

			«ELSEIF from != Type.BOOL && to == Type.OBJECT»
				static <A> «shortName»<A> from«from.javaPrefix»Function(final «from.javaPrefix»Function<A> f) {
					requireNonNull(f);
					return value -> requireNonNull(f.apply(value));
				}

			«ELSEIF from == Type.BOOL && to == Type.OBJECT»
				static <A> «shortName»<A> fromFunction(final Function<Boolean, A> f) {
					requireNonNull(f);
					return value -> requireNonNull(f.apply(value));
				}

			«ELSEIF from == Type.OBJECT && to != Type.BOOL»
				static <A> «shortName»<A> fromTo«to.javaPrefix»Function(final To«to.javaPrefix»Function<A> f) {
					requireNonNull(f);
					return a -> f.applyAs«to.typeName»(requireNonNull(a));
				}

			«ELSEIF from == Type.OBJECT && to == Type.BOOL»
				static <A> «shortName»<A> fromPredicate(final Predicate<A> p) {
					requireNonNull(p);
					return a -> p.test(requireNonNull(a));
				}

			«ELSEIF from == to && to != Type.BOOL»
				static «shortName» from«from.javaPrefix»UnaryOperator(final «from.javaPrefix»UnaryOperator op) {
					requireNonNull(op);
					return op::applyAs«from.typeName»;
				}
			«ELSEIF from == Type.BOOL && to == Type.BOOL»
				static «shortName» fromUnaryOperator(final UnaryOperator<Boolean> op) {
					requireNonNull(op);
					return op::apply;
				}

				static «shortName» fromPredicate(final Predicate<Boolean> p) {
					requireNonNull(p);
					return p::test;
				}
			«ELSEIF to == Type.BOOL»
				static «shortName» from«from.javaPrefix»Predicate(final «from.javaPrefix»Predicate p) {
					requireNonNull(p);
					return p::test;
				}
			«ELSEIF from != Type.BOOL && to != Type.BOOL»
				static «shortName» from«from.javaPrefix»To«to.javaPrefix»Function(final «from.javaPrefix»To«to.javaPrefix»Function f) {
					requireNonNull(f);
					return f::applyAs«to.typeName»;
				}
			«ELSEIF from == Type.BOOL»
				static «shortName» fromTo«to.javaPrefix»Function(final To«to.javaPrefix»Function<Boolean> f) {
					requireNonNull(f);
					return f::applyAs«to.typeName»;
				}
			«ENDIF»
			«IF from == Type.OBJECT && to == Type.OBJECT»
				«cast(#["A", "B"], #["A"], #["B"])»
			«ELSEIF from == Type.OBJECT»
				«cast(#["A"], #["A"], #[])»
			«ELSEIF to == Type.OBJECT»
				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}