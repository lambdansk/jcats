package jcats.generator.collection

import com.google.common.collect.Iterables
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class CommonGenerator implements ClassGenerator {
	override className() { "jcats.collection.Common" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.AbstractCollection;
		import java.util.AbstractList;
		import java.util.AbstractMap;
		import java.util.AbstractSet;
		import java.util.Arrays;
		import java.util.Collection;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.List;
		import java.util.ListIterator;
		import java.util.Map;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.BiFunction;
		import java.util.function.Consumer;
		import java.util.function.IntConsumer;
		import java.util.function.DoubleConsumer;
		import java.util.function.LongConsumer;
		import java.util.function.Function;
		import java.util.function.Predicate;
		import java.util.function.UnaryOperator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;

		final class Common {
			«FOR type : Type.values»
				static final «type.javaName»[] «type.emptyArrayName» = new «type.javaName»[0];
			«ENDFOR»
			«FOR type : Type.javaUnboxedTypes»
				«IF type.integral»
					static final «type.typeName»«type.typeName»«type.typeName»F2 SUM_«type.javaName.toUpperCase» = «type.boxedName»::sum;
				«ENDIF»
			«ENDFOR»

			/**
			 * The maximum size of array to allocate.
			 * Some VMs reserve some header words in an array.
			 * Attempts to allocate larger arrays may result in
			 * OutOfMemoryError: Requested array size exceeds VM limit
			 */
			static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

			private Common() {
			}

			«FOR type : Type.javaUnboxedTypes»
				static void reverse«type.shortName("Array")»(final «type.javaName»[] array) {
					for (int i = 0; i < array.length / 2; i++) {
						final «type.javaName» tmp = array[i];
						array[i] = array[array.length - i - 1];
						array[array.length - i - 1] = tmp;
					}
				}

			«ENDFOR»
			static void sortBooleanArrayAsc(final boolean[] array) {
				if (array.length > 1) {
					int countFalse = 0;
					for (final boolean value : array) {
						if (!value) {
							countFalse++;
						}
					}
					Arrays.fill(array, 0, countFalse, false);
					Arrays.fill(array, countFalse, array.length, true);
				}
			}

			static void sortBooleanArrayDesc(final boolean[] array) {
				if (array.length > 1) {
					int countTrue = 0;
					for (final boolean value : array) {
						if (value) {
							countTrue++;
						}
					}
					Arrays.fill(array, 0, countTrue, true);
					Arrays.fill(array, countTrue, array.length, false);
				}
			}

			«FOR type : Type.values»
				static «type.javaName»[] concatArrays(final «type.javaName»[] prefix, final «type.javaName»[] suffix) {
					final int length = prefix.length + suffix.length;
					if (length >= 0) {
						final «type.javaName»[] result = new «type.javaName»[length];
						System.arraycopy(prefix, 0, result, 0, prefix.length);
						System.arraycopy(suffix, 0, result, prefix.length, suffix.length);
						return result;
					} else {
						throw new SizeOverflowException();
					}
				}

			«ENDFOR»
			«FOR type : Type.values»
				static «type.javaName»[] updateArray(final «type.javaName»[] array, final int index, final «type.endoGenericName.replaceAll("<A, A>", "")» f) {
					final «type.javaName»[] result = new «type.javaName»[array.length];
					System.arraycopy(array, 0, result, 0, array.length);
					final «type.javaName» oldValue = array[index];
					final «type.javaName» newValue = f.apply(oldValue);
					result[index] = «type.requireNonNull("newValue")»;
					return result;
				}

			«ENDFOR»
			static int iterableSize(final Iterable<?> iterable) {
				final int[] size = {0};
				iterable.forEach((final Object __) -> {
					size[0]++;
					if (size[0] < 0) {
						throw new SizeOverflowException();
					}
				});
				return size[0];
			}

			«FOR type : Type.values»
				static boolean «type.indexedContainerShortName.firstToLowerCase»sEqual(final «type.indexedContainerWildcardName» c1, final «type.indexedContainerWildcardName» c2) {
					if (c1.hasKnownFixedSize() && c2.hasKnownFixedSize()) {
						if (c1.size() == c2.size()) {
							final «type.iteratorWildcardName» iterator1 = c1.iterator();
							final «type.iteratorWildcardName» iterator2 = c2.iterator();
							while (iterator1.hasNext()) {
								«IF type == Type.OBJECT»
									final Object o1 = iterator1.next();
									final Object o2 = requireNonNull(iterator2.next());
									if (!o1.equals(o2)) {
										return false;
									}
								«ELSE»
									final «type.javaName» o1 = iterator1.«type.iteratorNext»();
									final «type.javaName» o2 = iterator2.«type.iteratorNext»();
									if (o1 != o2) {
										return false;
									}
								«ENDIF»
							}
							return true;
						} else {
							return false;
						}
					} else {
						final «type.iteratorWildcardName» iterator1 = c1.iterator();
						final «type.iteratorWildcardName» iterator2 = c2.iterator();
						while (iterator1.hasNext() && iterator2.hasNext()) {
							«IF type == Type.OBJECT»
								final Object o1 = iterator1.next();
								final Object o2 = requireNonNull(iterator2.next());
								if (!o1.equals(o2)) {
									return false;
								}
							«ELSE»
								final «type.javaName» o1 = iterator1.«type.iteratorNext»();
								final «type.javaName» o2 = iterator2.«type.iteratorNext»();
								if (o1 != o2) {
									return false;
								}
							«ENDIF»
						}
						return !(iterator1.hasNext() || iterator2.hasNext());
					}
				}

			«ENDFOR»
			«FOR type : Type.values.filter[it != Type.BOOLEAN]»
				static boolean «type.uniqueContainerShortName.firstToLowerCase»sEqual(final «type.uniqueContainerShortName» c1, final «type.uniqueContainerShortName» c2) {
					if (c1.size() == c2.size()) {
						«IF type == Type.OBJECT || type == Type.BOOLEAN»
							for (final «type.javaName» value : c1) {
								if (!c2.contains(value)) {
									return false;
								}
							}
						«ELSE»
							final «type.iteratorGenericName» iterator1 = c1.iterator();
							while (iterator1.hasNext()) {
								final «type.javaName» value = iterator1.«type.iteratorNext»();
								if (!c2.contains(value)) {
									return false;
								}
							}
						«ENDIF»
						return true;
					} else {
						return false;
					}
				}

			«ENDFOR»
			static boolean keyValuesEqual(final KeyValue<Object, ?> keyValue1, final KeyValue<Object, ?> keyValue2) {
				if (keyValue1.size() == keyValue2.size()) {
					for (final P<?, ?> entry : keyValue1) {
						final Object value = keyValue2.getOrNull(entry.get1());
						if (value == null || !value.equals(entry.get2())) {
							return false;
						}
					}
					return true;
				} else {
					return false;
				}
			}

			static String iterableToString(final Iterable<?> iterable) {
				final Iterator<?> iterator = iterable.iterator();
				if (iterator.hasNext()) {
					final StringBuilder builder = new StringBuilder();
					builder.append("[");
					while (true) {
						final Object next = iterator.next();
						if (next == iterable) {
							builder.append("(this Iterable)");
						} else {
							builder.append(next);
						}
						if (!iterator.hasNext()) {
							builder.append("]");
							return builder.toString();
						}
						builder.append(", ");
					}
				} else {
					return "[]";
				}
			}

			«FOR type : Type.javaUnboxedTypes»
				static String «type.containerShortName.firstToLowerCase»ToString(final «type.containerWildcardName» container) {
					final «type.iteratorGenericName» iterator = container.iterator();
					if (iterator.hasNext()) {
						final StringBuilder builder = new StringBuilder();
						builder.append("[");
						while (true) {
							builder.append(iterator.«type.iteratorNext»());
							if (!iterator.hasNext()) {
								builder.append("]");
								return builder.toString();
							}
							builder.append(", ");
						}
					} else {
						return "[]";
					}
				}

			«ENDFOR»
			static <K, A> String keyValueToString(final KeyValue<K, A> keyValue) {
				final Iterator<P<K, A>> iterator = keyValue.iterator();
				if (iterator.hasNext()) {
					final StringBuilder builder = new StringBuilder();
					builder.append("{");
					while (true) {
						final P<K, A> next = iterator.next();
						final K key = next.get1();
						final A value = next.get2();
						if (key == keyValue) {
							builder.append("(this KeyValue)");
						} else {
							builder.append(key);
						}
						builder.append('=');
						if (value == keyValue) {
							builder.append("(this KeyValue)");
						} else {
							builder.append(value);
						}
						if (!iterator.hasNext()) {
							builder.append("}");
							return builder.toString();
						}
						builder.append(", ");
					}
				} else {
					return "{}";
				}
			}

			static <A> int orderedContainerHashCode(final OrderedContainer<A> container) {
				return container.foldToInt(1, (hashCode, value) -> 31 * hashCode + value.hashCode());
			}

			«FOR type : Type.primitives»
				static int «type.orderedContainerShortName.firstToLowerCase»HashCode(final «type.orderedContainerWildcardName» container) {
					return container.foldToInt(1, (hashCode, value) -> 31 * hashCode + «type.genericBoxedName».hashCode(value));
				}

			«ENDFOR»
			static <A> int uniqueContainerHashCode(final UniqueContainer<A> container) {
				return container.foldToInt(0, (hashCode, value) -> hashCode + value.hashCode());
			}

			«FOR type : Type.primitives.filter[it != Type.BOOLEAN]»
				static int «type.uniqueContainerShortName.firstToLowerCase»HashCode(final «type.containerWildcardName» container) {
					return container.foldToInt(0, (hashCode, value) -> hashCode + «type.genericBoxedName».hashCode(value));
				}

			«ENDFOR»
			static void sliceRangeCheck(final int fromIndexInclusive, final int toIndexExclusive) {
				if (fromIndexInclusive < 0) {
					throw new IndexOutOfBoundsException("fromIndex = " + fromIndexInclusive);
				} else if (fromIndexInclusive > toIndexExclusive) {
					throw new IllegalArgumentException(
							"fromIndex (" + fromIndexInclusive + ") > toIndex (" + toIndexExclusive + ")");
				}
			}

			static void sliceRangeCheck(final int fromIndexInclusive, final int toIndexExclusive, final int size) {
				sliceRangeCheck(fromIndexInclusive, toIndexExclusive);
				if (toIndexExclusive > size) {
					throw new IndexOutOfBoundsException("toIndex (" + toIndexExclusive + ") > size (" + size + ")");
				}
			}

			static String getIndexOutOfBoundsMessage(final int index, final Sized sized) {
				final String message = "Index " + index + " is out of range";
				if (sized.hasKnownFixedSize()) {
					return message + " (size = " + sized.size() + ")";
				} else {
					return message;
				}
			}

			static int clearBit(final int bits, final int bit) {
				return bits & (~bit);
			}
			«FOR type : Type.primitives»

				static Object[] «type.containerShortName.firstToLowerCase»ToArray(final «type.containerShortName» container) {
					if (container.hasKnownFixedSize()) {
						if (container.isEmpty()) {
							return EMPTY_OBJECT_ARRAY;
						} else {
							final Object[] array = new Object[container.size()];
							container.foreachWithIndex((final int index, final «type.genericName» value) -> array[index] = value);
							return array;
						}
					} else {
						final ArrayBuilder<Object> builder = Array.builder();
						container.foreach(builder::append);
						return builder.buildArray();
					}
				}
			«ENDFOR»
		}

		«FOR type : Type.values»
			final class «IF type == Type.OBJECT»ArrayIterator<A>«ELSE»«type.typeName»ArrayIterator«ENDIF» implements «type.iteratorGenericName» {
				private int i;
				private final «type.javaName»[] array;

				«IF type != Type.OBJECT»«type.typeName»«ENDIF»ArrayIterator(final «type.javaName»[] array) {
					this.array = array;
				}

				@Override
				public boolean hasNext() {
					return (this.i < this.array.length);
				}

				@Override
				public «type.genericJavaUnboxedName» «type.iteratorNext»() {
					try {
						final «type.genericName» next = «type.genericCast»this.array[this.i];
						this.i++;
						return next;
					} catch (final IndexOutOfBoundsException __) {
						throw new NoSuchElementException();
					}
				}

				@Override
				«IF type.javaUnboxedType»
					public void forEachRemaining(final «type.typeName»Consumer action) {
				«ELSE»
					public void forEachRemaining(final Consumer<? super «type.genericBoxedName»> action) {
				«ENDIF»
					requireNonNull(action);
					while (this.i < this.array.length) {
						action.accept(«type.genericCast»this.array[this.i++]);
					}
				}
			}

		«ENDFOR»
		«FOR type : Type.values»
			final class «IF type == Type.OBJECT»ArrayReverseIterator<A>«ELSE»«type.typeName»ArrayReverseIterator«ENDIF» implements «type.iteratorGenericName» {
				private int i;
				private final «type.javaName»[] array;

				«IF type != Type.OBJECT»«type.typeName»«ENDIF»ArrayReverseIterator(final «type.javaName»[] array) {
					«IF ea»
						assert array.length > 0;
					«ENDIF»
					this.array = array;
					this.i = array.length - 1;
				}

				@Override
				public boolean hasNext() {
					return (this.i >= 0);
				}

				@Override
				public «type.genericJavaUnboxedName» «type.iteratorNext»() {
					try {
						final «type.genericName» next = «type.genericCast»this.array[this.i];
						this.i--;
						return next;
					} catch (final IndexOutOfBoundsException __) {
						throw new NoSuchElementException();
					}
				}

				@Override
				«IF type.javaUnboxedType»
					public void forEachRemaining(final «type.typeName»Consumer action) {
				«ELSE»
					public void forEachRemaining(final Consumer<? super «type.genericBoxedName»> action) {
				«ENDIF»
					requireNonNull(action);
					while (this.i >= 0) {
						action.accept(«type.genericCast»this.array[this.i--]);
					}
				}
			}

		«ENDFOR»
		final class ListReverseIterator<A> implements Iterator<A> {
			private final ListIterator<A> iterator;

			ListReverseIterator(final List<A> list, final int index) {
				this.iterator = list.listIterator(index);
			}

			@Override
			public boolean hasNext() {
				return this.iterator.hasPrevious();
			}

			@Override
			public A next() {
				return this.iterator.previous();
			}
		}

		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»ListReverseIterator implements «type.iteratorGenericName» {
				private final ListIterator<«type.boxedName»> iterator;

				«type.typeName»ListReverseIterator(final List<«type.boxedName»> list, final int index) {
					this.iterator = list.listIterator(index);
				}

				@Override
				public boolean hasNext() {
					return this.iterator.hasPrevious();
				}

				@Override
				public «type.javaName» next«type.typeName»() {
					return this.iterator.previous();
				}
			}

		«ENDFOR»
		final class MappedIterator<A, B> implements Iterator<B> {
			private final Iterator<A> iterator;
			private final F<A, B> f;

			MappedIterator(final Iterator<A> iterator, final F<A, B> f) {
				this.iterator = iterator;
				this.f = f;
			}

			@Override
			public boolean hasNext() {
				return this.iterator.hasNext();
			}

			@Override
			public B next() {
				final A next = requireNonNull(this.iterator.next());
				return requireNonNull(this.f.apply(next));
			}

			@Override
			public void forEachRemaining(final Consumer<? super B> action) {
				requireNonNull(action);
				this.iterator.forEachRemaining((final A value) -> {
					final B mapped = requireNonNull(this.f.apply(value));
					action.accept(mapped);
				});
			}
		}

		«FOR fromType : Type.values»
			«FOR toType : Type.values»
				«IF fromType != Type.OBJECT || toType != Type.OBJECT»
					final class Mapped«fromType.typeName»«toType.typeName»Iterator«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» implements «toType.iteratorGenericName» {
						private final «fromType.iteratorGenericName» iterator;
						private final «IF fromType != Type.OBJECT»«fromType.typeName»«ENDIF»«toType.typeName»F«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» f;

						Mapped«fromType.typeName»«toType.typeName»Iterator(final «fromType.iteratorGenericName» iterator, final «IF fromType != Type.OBJECT»«fromType.typeName»«ENDIF»«toType.typeName»F«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» f) {
							this.iterator = iterator;
							this.f = f;
						}

						@Override
						public boolean hasNext() {
							return this.iterator.hasNext();
						}

						@Override
						public «toType.genericJavaUnboxedName» «toType.iteratorNext»() {
							final «fromType.iteratorReturnType» value = «fromType.requireNonNull('''this.iterator.«fromType.iteratorNext»()''')»;
							return «toType.requireNonNull("this.f.apply(value)")»;
						}

						@Override
						«IF toType.javaUnboxedType»
							public void forEachRemaining(final «toType.typeName»Consumer action) {
						«ELSE»
							public void forEachRemaining(final Consumer<? super «toType.genericBoxedName»> action) {
						«ENDIF»
							requireNonNull(action);
							this.iterator.forEachRemaining((final «fromType.genericJavaUnboxedName» value) -> {
								final «toType.genericName» mapped = «toType.requireNonNull("this.f.apply(value)")»;
								action.accept(mapped);
							});
						}
					}

				«ENDIF»
			«ENDFOR»
		«ENDFOR»
		final class MappedWithIndexIterator<A, B> implements Iterator<B> {
			private final Iterator<A> iterator;
			private final IntObjectObjectF2<A, B> f;
			private int i;
		
			MappedWithIndexIterator(final Iterator<A> iterator, final IntObjectObjectF2<A, B> f) {
				this.iterator = iterator;
				this.f = f;
			}
		
			@Override
			public boolean hasNext() {
				checkOverflow();
				return this.iterator.hasNext();
			}
		
			@Override
			public B next() {
				checkOverflow();
				final A next = requireNonNull(this.iterator.next());
				return requireNonNull(this.f.apply(this.i++, next));
			}
		
			@Override
			public void forEachRemaining(final Consumer<? super B> action) {
				requireNonNull(action);
				this.iterator.forEachRemaining((final A value) -> {
					checkOverflow();
					final B mapped = requireNonNull(this.f.apply(this.i++, value));
					action.accept(mapped);
				});
			}

			private void checkOverflow() {
				if (this.i < 0) {
					throw new SizeOverflowException();
				}
			}
		}

		«FOR type : Type.primitives»
			final class «type.typeName»MappedWithIndexIterator<A> implements Iterator<A> {
				private final «type.iteratorGenericName» iterator;
				private final Int«type.typeName»ObjectF2<A> f;
				private int i;
			
				«type.typeName»MappedWithIndexIterator(final «type.iteratorGenericName» iterator, final Int«type.typeName»ObjectF2<A> f) {
					this.iterator = iterator;
					this.f = f;
				}
			
				@Override
				public boolean hasNext() {
					checkOverflow();
					return this.iterator.hasNext();
				}
			
				@Override
				public A next() {
					checkOverflow();
					final «type.genericName» next = this.iterator.«type.iteratorNext»();
					return requireNonNull(this.f.apply(this.i++, next));
				}
			
				@Override
				public void forEachRemaining(final Consumer<? super A> action) {
					requireNonNull(action);
					this.iterator.forEachRemaining((final «type.iteratorReturnType» value) -> {
						checkOverflow();
						final A mapped = requireNonNull(this.f.apply(this.i++, value));
						action.accept(mapped);
					});
				}

				private void checkOverflow() {
					if (this.i < 0) {
						throw new SizeOverflowException();
					}
				}
			}

		«ENDFOR»
		final class FlatMappedIterator<A, B> implements Iterator<B> {
			private final Iterator<A> iterator;
			private final F<A, Iterable<B>> f;
			private Iterator<B> targetIterator;

			FlatMappedIterator(final Iterator<A> iterator, final F<A, Iterable<B>> f) {
				this.iterator = iterator;
				this.f = f;
			}

			@Override
			public boolean hasNext() {
				if (this.targetIterator != null && this.targetIterator.hasNext()) {
					return true;
				} else if (this.iterator.hasNext()) {
					final A next = requireNonNull(this.iterator.next());
					final Iterable<B> targetIterable = this.f.apply(next);
					this.targetIterator = targetIterable.iterator();
					return this.targetIterator.hasNext();
				} else {
					return false;
				}
			}

			@Override
			public B next() {
				if (hasNext()) {
					return requireNonNull(this.targetIterator.next());
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		«FOR fromType : Type.values»
			«FOR toType : Type.values»
				«IF fromType != Type.OBJECT || toType != Type.OBJECT»
					final class FlatMapped«fromType.typeName»«toType.typeName»Iterator«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» implements «toType.iteratorGenericName» {
						private final «fromType.iteratorGenericName» iterator;
						private final «IF fromType != Type.OBJECT»«fromType.typeName»Object«ENDIF»F<«IF fromType == Type.OBJECT»A, «ENDIF»Iterable<«toType.genericBoxedName»>> f;
						private «toType.iteratorGenericName» targetIterator;

						FlatMapped«fromType.typeName»«toType.typeName»Iterator(final «fromType.iteratorGenericName» iterator, final «IF fromType != Type.OBJECT»«fromType.typeName»Object«ENDIF»F<«IF fromType == Type.OBJECT»A, «ENDIF»Iterable<«toType.genericBoxedName»>> f) {
							this.iterator = iterator;
							this.f = f;
						}

						@Override
						public boolean hasNext() {
							if (this.targetIterator != null && this.targetIterator.hasNext()) {
								return true;
							} else if (this.iterator.hasNext()) {
								«IF fromType == Type.OBJECT»
									final «fromType.genericName» next = requireNonNull(this.iterator.«fromType.iteratorNext»());
								«ELSE»
									final «fromType.genericName» next = this.iterator.«fromType.iteratorNext»();
								«ENDIF»
								final Iterable<«toType.genericBoxedName»> targetIterable = this.f.apply(next);
								«IF toType.javaUnboxedType»
									this.targetIterator = «toType.typeName»Iterator.getIterator(targetIterable.iterator());
								«ELSE»
									this.targetIterator = targetIterable.iterator();
								«ENDIF»
								return this.targetIterator.hasNext();
							} else {
								return false;
							}
						}

						@Override
						public «toType.iteratorReturnType» «toType.iteratorNext»() {
							if (hasNext()) {
								return «toType.requireNonNull('''this.targetIterator.«toType.iteratorNext»()''')»;
							} else {
								throw new NoSuchElementException();
							}
						}
					}

				«ENDIF»
			«ENDFOR»
		«ENDFOR»
		final class FlatMappedReverseIterator<A, B> implements Iterator<B> {
			private final Iterator<A> reverseIterator;
			private final F<A, Iterable<B>> f;
			private Iterator<B> targetIterator;

			FlatMappedReverseIterator(final Iterator<A> reverseIterator, final F<A, Iterable<B>> f) {
				this.reverseIterator = reverseIterator;
				this.f = f;
			}

			@Override
			public boolean hasNext() {
				if (this.targetIterator != null && this.targetIterator.hasNext()) {
					return true;
				} else if (this.reverseIterator.hasNext()) {
					final A next = requireNonNull(this.reverseIterator.next());
					final Iterable<B> targetIterable = this.f.apply(next);
					if (targetIterable instanceof OrderedContainer<?>) {
						this.targetIterator = ((OrderedContainer<B>) targetIterable).reverseIterator();
					} else {
						this.targetIterator = Array.ofAll(targetIterable).reverseIterator();
					}
					return this.targetIterator.hasNext();
				} else {
					return false;
				}
			}

			@Override
			public B next() {
				if (hasNext()) {
					return requireNonNull(this.targetIterator.next());
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		«FOR fromType : Type.values»
			«FOR toType : Type.values»
				«IF fromType != Type.OBJECT || toType != Type.OBJECT»
					final class FlatMapped«fromType.typeName»«toType.typeName»ReverseIterator«IF fromType == Type.OBJECT || toType == Type.OBJECT»<A>«ENDIF» implements «toType.iteratorGenericName» {
						private final «fromType.iteratorGenericName» reverseIterator;
						private final «IF fromType != Type.OBJECT»«fromType.typeName»Object«ENDIF»F<«IF fromType == Type.OBJECT»A, «ENDIF»Iterable<«toType.genericBoxedName»>> f;
						private «toType.iteratorGenericName» targetIterator;

						FlatMapped«fromType.typeName»«toType.typeName»ReverseIterator(final «fromType.iteratorGenericName» reverseIterator, final «IF fromType != Type.OBJECT»«fromType.typeName»Object«ENDIF»F<«IF fromType == Type.OBJECT»A, «ENDIF»Iterable<«toType.genericBoxedName»>> f) {
							this.reverseIterator = reverseIterator;
							this.f = f;
						}

						@Override
						public boolean hasNext() {
							if (this.targetIterator != null && this.targetIterator.hasNext()) {
								return true;
							} else if (this.reverseIterator.hasNext()) {
								«IF fromType == Type.OBJECT»
									final «fromType.genericName» next = requireNonNull(this.reverseIterator.«fromType.iteratorNext»());
								«ELSE»
									final «fromType.genericName» next = this.reverseIterator.«fromType.iteratorNext»();
								«ENDIF»
								final Iterable<«toType.genericBoxedName»> targetIterable = this.f.apply(next);
								if (targetIterable instanceof «toType.orderedContainerWildcardName») {
									this.targetIterator = ((«toType.orderedContainerGenericName») targetIterable).reverseIterator();
								«IF toType != Type.OBJECT»
									} else if (targetIterable instanceof OrderedContainer<?>) {
										«IF toType.javaUnboxedType»
											this.targetIterator = «toType.typeName»Iterator.getIterator(((OrderedContainer<«toType.genericBoxedName»>) targetIterable).reverseIterator());
										«ELSE»
											this.targetIterator = ((OrderedContainer<«toType.genericBoxedName»>) targetIterable).reverseIterator();
										«ENDIF»
								«ENDIF»
								} else {
									this.targetIterator = «toType.arrayShortName».ofAll(targetIterable).reverseIterator();
								}
								return this.targetIterator.hasNext();
							} else {
								return false;
							}
						}

						@Override
						public «toType.iteratorReturnType» «toType.iteratorNext»() {
							if (hasNext()) {
								return «toType.requireNonNull('''this.targetIterator.«toType.iteratorNext»()''')»;
							} else {
								throw new NoSuchElementException();
							}
						}
					}

				«ENDIF»
			«ENDFOR»
		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("FilteredIterator")» implements «type.iteratorGenericName» {
				private final «type.iteratorGenericName» iterator;
				private final «type.boolFName» predicate;
				private boolean valueReady;
				private «type.iteratorReturnType» next;

				«type.shortName("FilteredIterator")»(final «type.iteratorGenericName» iterator, final «type.boolFName» predicate) {
					this.iterator = iterator;
					this.predicate = predicate;
				}

				@Override
				public boolean hasNext() {
					getNext();
					return this.valueReady;
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					getNext();
					if (this.valueReady) {
						this.valueReady = false;
						«IF type.primitive»
							return this.next;
						«ELSE»
							final «type.iteratorReturnType» result = this.next;
							this.next = null;
							return result;
						«ENDIF»
					} else {
						throw new NoSuchElementException();
					}
				}

				private void getNext() {
					if (!this.valueReady) {
						while (this.iterator.hasNext()) {
							final «type.iteratorReturnType» value = «type.requireNonNull('''this.iterator.«type.iteratorNext»()''')»;
							if (this.predicate.apply(value)) {
								this.next = value;
								this.valueReady = true;
								return;
							}
						}
					}
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					if (this.valueReady) {
						this.valueReady = false;
						«IF type.primitive»
							action.accept(this.next);
						«ELSE»
							final «type.iteratorReturnType» value = this.next;
							this.next = null;
							action.accept(value);
						«ENDIF»
					}
					while (this.iterator.hasNext()) {
						final «type.iteratorReturnType» value = «type.requireNonNull('''this.iterator.«type.iteratorNext»()''')»;
						if (this.predicate.apply(value)) {
							action.accept(value);
						}
					}
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("LimitedIterator")» implements «type.iteratorGenericName» {
				private final «type.iteratorGenericName» iterator;
				private final int limit;
				private int count;

				«type.shortName("LimitedIterator")»(final «type.iteratorGenericName» iterator, final int limit) {
					this.iterator = iterator;
					this.limit = limit;
				}

				@Override
				public boolean hasNext() {
					return (this.count < this.limit) && this.iterator.hasNext();
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					if (hasNext()) {
						this.count++;
						return this.iterator.«type.iteratorNext»();
					} else {
						throw new NoSuchElementException();
					}
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("SkippedIterator")» implements «type.iteratorGenericName» {
				private final «type.iteratorGenericName» iterator;
				private int skip;

				«type.shortName("SkippedIterator")»(final «type.iteratorGenericName» iterator, final int skip) {
					this.iterator = iterator;
					this.skip = skip;
				}

				@Override
				public boolean hasNext() {
					advance();
					return this.iterator.hasNext();
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					advance();
					return this.iterator.«type.iteratorNext»();
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					advance();
					this.iterator.forEachRemaining(action);
				}

				private void advance() {
					while (this.skip > 0 && this.iterator.hasNext()) {
						this.skip--;
						this.iterator.«type.iteratorNext»();
					}
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("TakenWhileIterator")» implements «type.iteratorGenericName» {
				private final «type.iteratorGenericName» iterator;
				private final «type.boolFName» predicate;
				private boolean valueReady;
				private boolean endOfData;
				private «type.genericName» next;

				«type.shortName("TakenWhileIterator")»(final «type.iteratorGenericName» iterator, final «type.boolFName» predicate) {
					this.iterator = iterator;
					this.predicate = predicate;
				}

				@Override
				public boolean hasNext() {
					getNext();
					return this.valueReady;
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					getNext();
					if (this.valueReady) {
						this.valueReady = false;
						return this.next;
					} else {
						throw new NoSuchElementException();
					}
				}

				private void getNext() {
					if (!this.valueReady && !this.endOfData && this.iterator.hasNext()) {
						final «type.genericName» value = «type.requireNonNull('''this.iterator.«type.iteratorNext»()''')»;
						if (this.predicate.apply(value)) {
							this.next = value;
							this.valueReady = true;
						} else {
							«IF type == Type.OBJECT»
								this.next = null;
							«ENDIF»
							this.valueReady = false;
							this.endOfData = true;
						}
					}
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					if (this.valueReady) {
						this.valueReady = false;
						final «type.genericName» value = this.next;
						«IF type == Type.OBJECT»
							this.next = null;
						«ENDIF»
						action.accept(value);
					}
					if (!this.endOfData) {
						while (this.iterator.hasNext()) {
							final «type.genericName» value = «type.requireNonNull('''this.iterator.«type.iteratorNext»()''')»;
							if (this.predicate.apply(value)) {
								action.accept(value);
							} else {
								this.endOfData = true;
								return;
							}
						}
					}
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			class «type.genericName("DroppedWhileIterator")» implements «type.iteratorGenericName» {
				private final «type.iteratorGenericName» iterator;
				private final «type.boolFName» predicate;
				private boolean advanced;
				private boolean firstReady;
				private «type.genericName» first;
			
				«type.shortName("DroppedWhileIterator")»(final «type.iteratorGenericName» iterator, final «type.boolFName» predicate) {
					this.iterator = iterator;
					this.predicate = predicate;
				}
			
				@Override
				public boolean hasNext() {
					advance();
					return this.firstReady || this.iterator.hasNext();
				}
			
				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					advance();
					if (this.firstReady) {
						final «type.genericName» value = this.first;
						this.firstReady = false;
						«IF type == Type.OBJECT»
							this.first = null;
						«ENDIF»
						return value;
					} else {
						return this.iterator.«type.iteratorNext»();
					}
				}
			
				private void advance() {
					if (!this.advanced) {
						while (this.iterator.hasNext()) {
							final «type.genericName» value = «type.requireNonNull('''this.iterator.«type.iteratorNext»()''')»;
							if (!this.predicate.apply(value)) {
								this.firstReady = true;
								this.first = value;
								break;
							}
						}
						this.advanced = true;
					}
				}
			
				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					advance();
					if (this.firstReady) {
						final «type.genericName» value = this.first;
						this.firstReady = false;
						«IF type == Type.OBJECT»
							this.first = null;
						«ENDIF»
						action.accept(value);
					}
					this.iterator.forEachRemaining(action);
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("TableIterator")» implements «type.iteratorGenericName» {
				private final int size;
				private final «type.intFGenericName» f;
				private int i;

				«type.shortName("TableIterator")»(final int size, final «type.intFGenericName» f) {
					this.size = size;
					this.f = f;
				}

				@Override
				public boolean hasNext() {
					return (this.i < this.size);
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					if (this.i < this.size) {
						return «type.requireNonNull("this.f.apply(this.i++)")»;
					} else {
						throw new NoSuchElementException();
					}
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					while (this.i < this.size) {
						action.accept(«type.requireNonNull("this.f.apply(this.i++)")»);
					}
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("ReverseTableIterator")» implements «type.iteratorGenericName» {
				private final «type.intFGenericName» f;
				private int i;

				«type.shortName("ReverseTableIterator")»(final int size, final «type.intFGenericName» f) {
					this.f = f;
					this.i = size - 1;
				}

				@Override
				public boolean hasNext() {
					return (this.i >= 0);
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					if (this.i >= 0) {
						return «type.requireNonNull("this.f.apply(this.i--)")»;
					} else {
						throw new NoSuchElementException();
					}
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					while (this.i >= 0) {
						action.accept(«type.requireNonNull("this.f.apply(this.i--)")»);
					}
				}
			}

		«ENDFOR»
		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»Iterator implements PrimitiveIterator.Of«type.typeName» {
				final Iterator<«type.boxedName»> iterator;

				private «type.typeName»Iterator(final Iterator<«type.boxedName»> iterator) {
					this.iterator = iterator;
				}

				@Override
				public boolean hasNext() {
					return this.iterator.hasNext();
				}

				@Override
				public «type.javaName» next«type.typeName»() {
					return this.iterator.next();
				}

				static PrimitiveIterator.Of«type.typeName» getIterator(final Iterator<«type.boxedName»> iterator) {
					if (iterator instanceof PrimitiveIterator.Of«type.typeName») {
						return (PrimitiveIterator.Of«type.typeName») iterator;
					} else {
						return new «type.typeName»Iterator(iterator);
					}
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("GeneratingIterator")» implements «type.iteratorGenericName» {
				private final «type.f0GenericName» f;

				«type.shortName("GeneratingIterator")»(final «type.f0GenericName» f) {
					this.f = f;
				}

				@Override
				public boolean hasNext() {
					return true;
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					return «type.requireNonNull("this.f.apply()")»;
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					throw new UnsupportedOperationException();
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("IteratingIterator")» implements «type.iteratorGenericName» {
				private «type.genericName» value;
				private boolean startReturned;
				private final «type.endoGenericName» f;

				«type.shortName("IteratingIterator")»(final «type.genericName» start, final «type.endoGenericName» f) {
					this.value = start;
					this.f = f;
				}

				@Override
				public boolean hasNext() {
					return true;
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					if (this.startReturned) {
						this.value = «type.requireNonNull("this.f.apply(this.value)")»;
					} else {
						this.startReturned = true;
					}
					return this.value;
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					throw new UnsupportedOperationException();
				}
			}

		«ENDFOR»
		«FOR type : Iterables.concat(#[Type.OBJECT], Type.javaUnboxedTypes)»
			final class «type.genericName("IteratingWhileIterator")» implements «type.iteratorGenericName» {
				private «type.genericName» value;
				private boolean valueChecked;
				private boolean valueOk;
				private final «type.boolFName» hasNext;
				private final «type.endoGenericName» next;

				«type.shortName("IteratingWhileIterator")»(final «type.genericName» start, final «type.boolFName» hasNext, final «type.endoGenericName» next) {
					this.value = start;
					this.hasNext = hasNext;
					this.next = next;
				}

				@Override
				public boolean hasNext() {
					if (!this.valueChecked) {
						this.valueOk = this.hasNext.apply(this.value);
						this.valueChecked = true;
					}
					return this.valueOk;
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					if (!this.valueChecked) {
						this.valueOk = this.hasNext.apply(this.value);
						this.valueChecked = true;
					}
					if (this.valueOk) {
						final «type.genericName» returnValue = this.value;
						this.value = «type.requireNonNull("this.next.apply(this.value)")»;
						this.valueChecked = false;
						return returnValue;
					} else {
						throw new NoSuchElementException();
					}
				}
			}

		«ENDFOR»
		final class ConcatenatedIterator<A> implements Iterator<A> {
			private final Iterator<A>[] iterators;
			private int i;

			ConcatenatedIterator(final Iterator<A>[] iterators) {
				«IF ea»
					assert iterators.length > 1;
				«ENDIF»
				this.iterators = iterators;
			}

			@Override
			public boolean hasNext() {
				while (this.i < this.iterators.length) {
					if (this.iterators[this.i].hasNext()) {
						return true;
					}
					this.i++;
				}
				return false;
			}

			@Override
			public A next() {
				while (this.i < this.iterators.length) {
					final Iterator<A> iterator = this.iterators[this.i];
					if (iterator.hasNext()) {
						return requireNonNull(iterator.next());
					}
					this.i++;
				}
				throw new NoSuchElementException();
			}

			@Override
			public void forEachRemaining(final Consumer<? super A> action) {
				requireNonNull(action);
				while (this.i < this.iterators.length) {
					this.iterators[this.i].forEachRemaining(action);
					this.i++;
				}
			}
		}

		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»ConcatenatedIterator implements «type.iteratorGenericName» {
				private final «type.iteratorGenericName»[] iterators;
				private int i;

				«type.typeName»ConcatenatedIterator(final «type.iteratorGenericName»[] iterators) {
					«IF ea»
						assert iterators.length > 1;
					«ENDIF»
					this.iterators = iterators;
				}

				@Override
				public boolean hasNext() {
					while (this.i < this.iterators.length) {
						if (this.iterators[this.i].hasNext()) {
							return true;
						}
						this.i++;
					}
					return false;
				}

				@Override
				public «type.iteratorReturnType» «type.iteratorNext»() {
					while (this.i < this.iterators.length) {
						final «type.iteratorGenericName» iterator = this.iterators[this.i];
						if (iterator.hasNext()) {
							return «type.requireNonNull('''iterator.«type.iteratorNext»()''')»;
						}
						this.i++;
					}
					throw new NoSuchElementException();
				}

				@Override
				public void forEachRemaining(final «type.forEachRemainingGenericActionName» action) {
					requireNonNull(action);
					while (this.i < this.iterators.length) {
						this.iterators[this.i].forEachRemaining(action);
						this.i++;
					}
				}
			}

		«ENDFOR»
		final class MappedSpliterator<A, B> implements Spliterator<B> {
			private final Spliterator<A> spliterator;
			private final F<A, B> f;

			MappedSpliterator(final Spliterator<A> spliterator, final F<A, B> f) {
				this.spliterator = spliterator;
				this.f = f;
			}

			@Override
			public boolean tryAdvance(final Consumer<? super B> action) {
				return this.spliterator.tryAdvance((final A value) -> action.accept(this.f.apply(value)));
			}

			@Override
			public void forEachRemaining(final Consumer<? super B> action) {
				this.spliterator.forEachRemaining((final A value) -> action.accept(this.f.apply(value)));
			}

			@Override
			public Spliterator<B> trySplit() {
				return new MappedSpliterator<>(this.spliterator.trySplit(), this.f);
			}

			@Override
			public long estimateSize() {
				return this.spliterator.estimateSize();
			}

			@Override
			public long getExactSizeIfKnown() {
				return this.spliterator.getExactSizeIfKnown();
			}

			@Override
			public int characteristics() {
				return this.spliterator.characteristics();
			}

			@Override
			public boolean hasCharacteristics(final int characteristics) {
				return this.spliterator.hasCharacteristics(characteristics);
			}
		}

		«FOR type : Type.javaUnboxedTypes»
			final class «type.typeName»Spliterator implements Spliterator.Of«type.typeName» {
				final Spliterator<«type.boxedName»> spliterator;

				private «type.typeName»Spliterator(final Spliterator<«type.boxedName»> spliterator) {
					this.spliterator = spliterator;
				}

				@Override
				public Spliterator.Of«type.typeName» trySplit() {
					final Spliterator<«type.boxedName»> split = this.spliterator.trySplit();
					if (split == null) {
						return null;
					} else {
						return getSpliterator(split);
					}
				}

				@Override
				public long estimateSize() {
					return this.spliterator.estimateSize();
				}

				@Override
				public long getExactSizeIfKnown() {
					return this.spliterator.getExactSizeIfKnown();
				}

				@Override
				public int characteristics() {
					return this.spliterator.characteristics();
				}

				@Override
				public boolean hasCharacteristics(final int characteristics) {
					return this.spliterator.hasCharacteristics(characteristics);
				}

				@Override
				public boolean tryAdvance(final «type.typeName»Consumer action) {
					return this.spliterator.tryAdvance(action::accept);
				}

				static Spliterator.Of«type.typeName» getSpliterator(final Spliterator<«type.boxedName»> iterator) {
					if (iterator instanceof Spliterator.Of«type.typeName») {
						return (Spliterator.Of«type.typeName») iterator;
					} else {
						return new «type.typeName»Spliterator(iterator);
					}
				}
			}

		«ENDFOR»
		final class Product2Iterator<A1, A2, B> implements Iterator<B> {
			private final Iterator<A1> iterator1;
			private final Iterable<A2> iterable2;
			private final F2<A1, A2, B> f;
			private A1 a1;
			private Iterator<A2> iterator2;

			Product2Iterator(final Iterable<A1> iterable1, final Iterable<A2> iterable2, final F2<A1, A2, B> f) {
				this.iterator1 = iterable1.iterator();
				this.iterable2 = iterable2;
				this.f = f;
				this.a1 = iterator1.next();
				this.iterator2 = iterable2.iterator();
			}

			@Override
			public boolean hasNext() {
				return iterator1.hasNext() || iterator2.hasNext();
			}

			@Override
			public B next() {
				if (iterator2.hasNext()) {
					return f.apply(a1, iterator2.next());
				} else if (iterator1.hasNext()) {
					a1 = iterator1.next();
					iterator2 = iterable2.iterator();
					return f.apply(a1, iterator2.next());
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class Product3Iterator<A1, A2, A3, B> implements Iterator<B> {
			private final Iterator<A1> iterator1;
			private final Iterable<A2> iterable2;
			private final Iterable<A3> iterable3;
			private final F3<A1, A2, A3, B> f;
			private A1 a1;
			private A2 a2;
			private Iterator<A2> iterator2;
			private Iterator<A3> iterator3;

			Product3Iterator(final Iterable<A1> iterable1, final Iterable<A2> iterable2, final Iterable<A3> iterable3, final F3<A1, A2, A3, B> f) {
				this.iterator1 = iterable1.iterator();
				this.iterable2 = iterable2;
				this.iterable3 = iterable3;
				this.f = f;
				this.a1 = iterator1.next();
				this.iterator2 = iterable2.iterator();
				this.a2 = iterator2.next();
				this.iterator3 = iterable3.iterator();
			}

			@Override
			public boolean hasNext() {
				return iterator1.hasNext() || iterator2.hasNext() || iterator3.hasNext();
			}

			@Override
			public B next() {
				if (iterator3.hasNext()) {
					return f.apply(a1, a2, iterator3.next());
				} else if (iterator2.hasNext()) {
					a2 = iterator2.next();
					iterator3 = iterable3.iterator();
					return f.apply(a1, a2, iterator3.next());
				} else if (iterator1.hasNext()) {
					a1 = iterator1.next();
					iterator2 = iterable2.iterator();
					a2 = iterator2.next();
					iterator3 = iterable3.iterator();
					return f.apply(a1, a2, iterator3.next());
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		abstract class AbstractImmutableCollection<A> extends AbstractCollection<A> {
			@Override
			public final boolean add(final A a) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean remove(final Object o) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeIf(final Predicate<? super A> filter) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean retainAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}
		}

		abstract class AbstractImmutableList<A> extends AbstractList<A> {
			@Override
			public final boolean add(final A a) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final int index, final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean remove(final Object o) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeIf(final Predicate<? super A> filter) {
				throw new UnsupportedOperationException();
			}

			@Override
			protected final void removeRange(final int fromIndex, final int toIndex) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void replaceAll(final UnaryOperator<A> operator) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean retainAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final A set(final int index, final A element) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void sort(final Comparator<? super A> c) {
				throw new UnsupportedOperationException();
			}
		}

		abstract class AbstractImmutableSet<A> extends AbstractSet<A> {
			@Override
			public final boolean add(final A a) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean addAll(final Collection<? extends A> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean remove(final Object o) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean removeIf(final Predicate<? super A> filter) {
				throw new UnsupportedOperationException();
			}

			@Override
			public final boolean retainAll(final Collection<?> c) {
				throw new UnsupportedOperationException();
			}
		}

		abstract class AbstractImmutableMap<K, A> extends AbstractMap<K, A> {
			@Override
			public void clear() {
				throw new UnsupportedOperationException();
			}

			@Override
			public A compute(final K key, final BiFunction<? super K, ? super A, ? extends A> remappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A computeIfAbsent(final K key, final Function<? super K, ? extends A> mappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A computeIfPresent(final K key, final BiFunction<? super K, ? super A, ? extends A> remappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A merge(final K key, final A value, final BiFunction<? super A, ? super A, ? extends A> remappingFunction) {
				throw new UnsupportedOperationException();
			}

			@Override
			public void putAll(final Map<? extends K, ? extends A> m) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A putIfAbsent(final K key, final A value) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A remove(final Object key) {
				throw new UnsupportedOperationException();
			}

			@Override
			public boolean remove(final Object key, final Object value) {
				throw new UnsupportedOperationException();
			}

			@Override
			public A replace(final K key, final A value) {
				throw new UnsupportedOperationException();
			}

			@Override
			public boolean replace(final K key, final A oldValue, final A newValue) {
				throw new UnsupportedOperationException();
			}

			@Override
			public void replaceAll(final BiFunction<? super K, ? super A, ? extends A> function) {
				throw new UnsupportedOperationException();
			}
		}

		final class ArrayCollection<A> extends AbstractCollection<A> {
			private final Object[] arr;

			ArrayCollection(final Object[] arr) {
				this.arr = arr;
			}

			@Override
			public Iterator<A> iterator() {
				return new ArrayIterator<>(arr);
			}

			@Override
			public int size() {
				return arr.length;
			}

			@Override
			public Object[] toArray() {
				return arr;
			}
		}

		final class ImmutableArrayList<A> extends AbstractImmutableList<A> implements RandomAccess, Serializable {
			private final Object[] arr;

			// Assume arr.length > 0
			ImmutableArrayList(final Object[] arr) {
				this.arr = arr;
			}

			@Override
			public A get(final int index) {
				return (A) arr[index];
			}

			@Override
			public int size() {
				return arr.length;
			}

			@Override
			public void forEach(final Consumer<? super A> action) {
				for (final Object value : arr) {
					action.accept((A) value);
				}
			}

			@Override
			public Iterator<A> iterator() {
				return new ArrayIterator<>(arr);
			}

			@Override
			public Spliterator<A> spliterator() {
				return Spliterators.spliterator(arr, Spliterator.ORDERED | Spliterator.IMMUTABLE);
			}
		}
	''' }
}
