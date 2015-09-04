package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.Generator

final class ListGenerator implements Generator {
	override className() { Constants.LIST }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		import java.util.Spliterator;
		import java.util.function.Predicate;
		import java.util.stream.Stream;
		import java.util.stream.StreamSupport;

		import «Constants.F»;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static java.util.Spliterators.emptySpliterator;
		import static java.util.Spliterators.spliteratorUnknownSize;

		public final class List<A> implements Iterable<A>, Serializable {
			private static final List NIL = new List(null, null);

			final A head;
			List<A> tail;

			private List(final A head, final List<A> tail) {
				this.head = head;
				this.tail = tail;
			}

			/**
			 * O(1)
			 */
			public boolean isEmpty() {
				return (this == NIL);
			}

			/**
			 * O(1)
			 */
			public boolean isNotEmpty() {
				return (this != NIL);
			}

			/**
			 * O(1)
			 */
			public A head() {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return head;
				}
			}

			/**
			 * O(1)
			 */
			public List<A> prepend(final A value) {
				return new List<>(requireNonNull(value), this);
			}

			/**
			 * O(this.size)
			 */
			public List<A> append(final A value) {
				final ListBuilder<A> builder = new ListBuilder<>();
				builder.appendList(this);
				builder.append(value);
				return builder.toList();
			}

			/**
			 * O(this.size)
			 */
			public List<A> concat(final List<A> suffix) {
				requireNonNull(suffix);
				if (isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return this;
				} else {
					final ListBuilder<A> builder = new ListBuilder<>();
					builder.appendList(this);
					return builder.prependToList(suffix);
				}
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public List<A> appendAll(final Iterable<A> suffix) {
				if (suffix instanceof List) {
					return concat((List<A>) suffix);
				} else {
					final ListBuilder<A> builder = new ListBuilder<>();
					builder.appendList(this);
					builder.appendAll(suffix);
					return builder.toList();
				}
			}

			/**
			 * O(prefix.size)
			 */
			public List<A> prependAll(final Iterable<A> prefix) {
				final ListBuilder<A> builder = new ListBuilder<>();
				builder.appendAll(prefix);
				return builder.prependToList(this);
			}

			/**
			 * O(this.size)
			 */
			public <B> List<B> map(final F<A, B> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return nil();
				} else if (f == F.id()) {
					return (List<B>) this;
				} else {
					final ListBuilder<B> builder = new ListBuilder<>();
					List<A> list = this;
					while (!list.isEmpty()) {
						builder.append(f.apply(list.head));
						list = list.tail;
					}
					return builder.toList();
				}
			}

			public <B> List<B> flatMap(final F<A, List<B>> f) {
				requireNonNull(f);
				if (isEmpty()) {
					return nil();
				} else {
					final ListBuilder<B> builder = new ListBuilder<>();
					List<A> list = this;
					while (!list.isEmpty()) {
						builder.appendList(f.apply(list.head));
						list = list.tail;
					}
					return builder.toList();
				}
			}

			public List<A> filter(final Predicate<A> predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return nil();
				} else {
					final ListBuilder<A> builder = new ListBuilder<>();
					List<A> list = this;
					while (!list.isEmpty()) {
						if (predicate.test(list.head)) {
							builder.append(list.head);
						}
						list = list.tail;
					}
					return builder.toList();
				}
			}

			public List<A> take(final int n) {
				if (isEmpty() || n <= 0) {
					return nil();
				} else {
					final ListBuilder<A> builder = new ListBuilder<>();
					List<A> list = this;
					int i = 0;
					while (!list.isEmpty() && i < n) {
						builder.append(list.head);
						list = list.tail;
						i++;
					}
					return builder.toList();
				}
			}

			public static <A> List<A> nil() {
				return NIL;
			}

			public static <A> List<A> singleList(final A value) {
				return new List<>(requireNonNull(value), nil());
			}

			@SafeVarargs
			public static <A> List<A> list(final A... values) {
				List<A> list = nil();
				for (int i = values.length - 1; i >= 0; i--) {
					list = new List<>(requireNonNull(values[i]), list);
				}
				return list;
			}

			«FOR primitive : PRIMITIVES»
				public static List<«primitive.boxedName»> «primitive.shortName»List(final «primitive»... values) {
					List<«primitive.boxedName»> list = nil();
					for (int i = values.length - 1; i >= 0; i--) {
						list = new List<>(values[i], list);
					}
					return list;
				}

			«ENDFOR»
			public static List<Character> stringToCharList(final String str) {
				if (str.isEmpty()) {
					return nil();
				} else {
					final ListBuilder<Character> builder = new ListBuilder<>();
					for (int i = 0; i < str.length(); i++) {
						builder.append(str.charAt(i));
					}
					return builder.toList();
				}
			}

			public static <A> List<A> iterableToList(final Iterable<A> values) {
				return new ListBuilder<A>().appendAll(values).toList();
			}

			@Override
			public Iterator<A> iterator() {
				return isEmpty() ? emptyIterator() : new ListIterator<>(this);
			}

			@Override
			public Spliterator<A> spliterator() {
				return isEmpty() ? emptySpliterator() : spliteratorUnknownSize(iterator(), Spliterator.IMMUTABLE);
			}

			«stream»

			«parallelStream»
		}
	''' }
}
