package jcats.generator.function

import jcats.generator.Generator
import jcats.generator.Constants

final class FGenerator implements Generator {
	override className() { Constants.F }

	override sourceCode() { '''
		package «Constants.FUNCTION»;

		import java.util.function.Function;
		
		import static java.util.Objects.requireNonNull;

		@FunctionalInterface
		public interface F<A, B> {
			B apply(final A a);

			default <C> F<A, C> map(final F<B, C> f) {
				requireNonNull(f);
				return a -> {
					requireNonNull(a);
					final B b = requireNonNull(apply(a));
					return f.apply(requireNonNull(b));
				};
			}

			default <C> F<C, B> contraMap(final F<C, A> f) {
				requireNonNull(f);
				return c -> {
					requireNonNull(c);
					final A a = requireNonNull(f.apply(c));
					return requireNonNull(apply(a));
				};
			}

			default <C> F<A, C> flatMap(final F<B, F<A, C>> f) {
				requireNonNull(f);
				return a -> {
					requireNonNull(a);
					final B b = requireNonNull(apply(a));
					return requireNonNull(f.apply(b).apply(a));
				};
			}

			default Function<A, B> toFunction() {
				return a -> {
					requireNonNull(a);
					return requireNonNull(apply(a));
				};
			}

			default Eff<A> toEff() {
				return a -> apply(requireNonNull(a));
			}

			static <A> F<A, A> id() {
				return (F<A, A>) Fs.ID;
			}

			static <A, B> F<A, B> constant(final B b) {
				requireNonNull(b);
				return __ -> b;
			}

			static <A, B> F<A, B> lazyConst(final F0<B> b) {
				return b.toConstF();
			}
		
			static <A, B> F<A, B> functionToF(final Function<A, B> f) {
				requireNonNull(f);
				return a -> {
					requireNonNull(a);
					return requireNonNull(f.apply(a));
				};
			}

			«widen("F", 2, true)»
		}
	''' }
}