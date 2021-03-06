package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class ArrayGenerator implements ClassGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new ArrayGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.arrayShortName }
	def genericName() { type.arrayGenericName }
	def diamondName() { type.diamondName("Array") }
	def wildcardName() { type.wildcardName("Array") }
	def paramGenericName() { type.paramGenericName("Array") }
	def arrayBuilderName() { type.genericName("ArrayBuilder") }
	def arrayBuilderDiamondName() { type.diamondName("ArrayBuilder") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.Arrays;
		import java.util.Collection;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.NoSuchElementException;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.RandomAccess;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.Consumer;
		import java.util.stream.Collector;
		import java.util.stream.«type.streamName»;
		«IF type.javaUnboxedType»
			import java.util.function.«type.typeName»Consumer;
		«ENDIF»

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Collections.emptyIterator;
		import static java.util.Objects.requireNonNull;
		import static «Constants.ARRAY».emptyArray;
		«FOR toType : Type.primitives.filter[it != type]»
			import static «Constants.COLLECTION».«toType.arrayShortName».empty«toType.arrayShortName»;
		«ENDFOR»
		«IF type == Type.OBJECT»
			import static «Constants.ORD».*;
		«ENDIF»
		import static «Constants.F».id;
		«IF type == Type.OBJECT»
			import static «Constants.FUNCTION».F.*;
		«ELSEIF type != Type.INT»
			import static «Constants.FUNCTION».«type.typeName»«type.typeName»F.*;
		«ENDIF»
		import static «Constants.FUNCTION».Int«type.typeName»F.*;
		import static «Constants.JCATS».Int«type.typeName»P.*;
		import static «Constants.COMMON».*;
		«IF type.javaUnboxedType»
			import static «Constants.JCATS».«type.typeName»Option.*;
		«ENDIF»
		import static «Constants.JCATS».IntOption.*;


		public final class «type.covariantName("Array")» implements «type.indexedContainerGenericName», Serializable {
			static final «wildcardName» EMPTY = new «diamondName»(«type.emptyArrayName»);

			final «type.javaName»[] array;

			«shortName»(final «type.javaName»[] array) {
				this.array = array;
			}

			/**
			 * O(1)
			 */
			@Override
			public int size() {
				return this.array.length;
			}

			/**
			 * O(1)
			 */
			@Override
			public «type.genericName» get(final int index) throws IndexOutOfBoundsException {
				try {
					return «type.genericCast»this.array[index];
				} catch (final ArrayIndexOutOfBoundsException __) {
					«indexOutOfBounds»
				}
			}

			/**
			 * O(size)
			 */
			public «genericName» set(final int index, final «type.genericName» value) throws IndexOutOfBoundsException {
				«IF type == Type.OBJECT»
					return update(index, always(value));
				«ELSE»
					return update(index, «type.typeName.firstToLowerCase»«type.typeName»Always(value));
				«ENDIF»
			}

			/**
			 * O(size)
			 */
			public «genericName» update(final int index, final «type.endoGenericName» f) throws IndexOutOfBoundsException {
				return new «diamondName»(updateArray(this.array, index, f));
			}

			/**
			 * O(size)
			 */
			public «genericName» prepend(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				final «type.javaName»[] result = new «type.javaName»[this.array.length + 1];
				System.arraycopy(this.array, 0, result, 1, this.array.length);
				result[0] = value;
				return new «diamondName»(result);
			}

			/**
			 * O(size)
			 */
			public «genericName» append(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				final «type.javaName»[] result = new «type.javaName»[this.array.length + 1];
				System.arraycopy(this.array, 0, result, 0, this.array.length);
				result[this.array.length] = value;
				return new «diamondName»(result);
			}

			public «genericName» init() throws NoSuchElementException {
				if (this.array.length == 0) {
					throw new NoSuchElementException();
				} else {
					final «type.javaName»[] result = new «type.javaName»[this.array.length - 1];
					System.arraycopy(this.array, 0, result, 0, result.length);
					return new «diamondName»(result);
				}
			}

			public «genericName» tail() throws NoSuchElementException {
				if (this.array.length == 0) {
					throw new NoSuchElementException();
				} else {
					final «type.javaName»[] result = new «type.javaName»[this.array.length - 1];
					System.arraycopy(this.array, 1, result, 0, result.length);
					return new «diamondName»(result);
				}
			}

			public «genericName» removeAt(final int index) throws IndexOutOfBoundsException {
				if (index < 0 || index >= this.array.length) {
					«indexOutOfBounds»
				} else {
					return remove(index);
				}
			}

			public «genericName» removeFirstWhere(final «type.boolFName» predicate) {
				final IntOption index = indexWhere(predicate);
				if (index.isEmpty()) {
					return this;
				} else {
					return remove(index.get());
				}
			}

			public «genericName» removeFirst(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return removeFirstWhere(value::equals);
				«ELSE»
					return removeFirstWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			public «genericName» removeLastWhere(final «type.boolFName» predicate) {
				final IntOption index = lastIndexWhere(predicate);
				if (index.isEmpty()) {
					return this;
				} else {
					return remove(index.get());
				}
			}

			public «genericName» removeLast(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					return removeLastWhere(value::equals);
				«ELSE»
					return removeLastWhere((final «type.javaName» a) -> a == value);
				«ENDIF»
			}

			private «genericName» remove(final int index) {
				if (this.array.length == 1) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] result = new «type.javaName»[this.array.length - 1];
					System.arraycopy(this.array, 0, result, 0, index);
					System.arraycopy(this.array, index + 1, result, index, this.array.length - index - 1);
					return new «diamondName»(result);
				}
			}

			/**
			 * O(prefix.size + suffix.size)
			 */
			private «genericName» concat(final «genericName» suffix) {
				requireNonNull(suffix);
				if (isEmpty()) {
					return suffix;
				} else if (suffix.isEmpty()) {
					return this;
				} else {
					return new «diamondName»(concatArrays(this.array, suffix.array));
				}
			}

			private static «IF type == Type.OBJECT»<A> «ENDIF»void fillArray(final «type.javaName»[] array, final int startIndex, final Iterable<«type.genericBoxedName»> iterable) {
				int i = startIndex;
				«IF type.javaUnboxedType»
					final «type.iteratorGenericName» iterator = «type.getIterator("iterable.iterator()")»;
					while (iterator.hasNext()) {
						array[i++] = iterator.next«type.typeName»();
					}
				«ELSE»
					for (final «type.genericName» value : iterable) {
						«IF type == Type.OBJECT»
							array[i++] = requireNonNull(value);
						«ELSE»
							array[i++] = value;
						«ENDIF»
					}
				«ENDIF»
			}

			private «genericName» appendSized(final Iterable<«type.genericBoxedName»> suffix, final int suffixSize) {
				if (suffixSize == 0) {
					return this;
				} else {
					final int length = this.array.length + suffixSize;
					if (length >= 0) {
						final «type.javaName»[] result = new «type.javaName»[length];
						System.arraycopy(this.array, 0, result, 0, this.array.length);
						«IF type == Type.OBJECT»
							fillArray(result, this.array.length, suffix);
						«ELSE»
							if (suffix instanceof Container<?>) {
								((Container<«type.boxedName»>) suffix).foreachWithIndex((final int index, final «type.boxedName» value) ->
										result[this.array.length + index] = value);
							} else {
								fillArray(result, this.array.length, suffix);
							}
						«ENDIF»
						return new «diamondName»(result);
					} else {
						throw new SizeOverflowException();
					}
				}
			}

			private «genericName» prependSized(final Iterable<«type.genericBoxedName»> prefix, final int prefixSize) {
				if (prefixSize == 0) {
					return this;
				} else {
					final int length = prefixSize + this.array.length;
					if (length >= 0) {
						final «type.javaName»[] result = new «type.javaName»[length];
						«IF type == Type.OBJECT»
							fillArray(result, 0, prefix);
						«ELSE»
							if (prefix instanceof Container<?>) {
								((Container<«type.boxedName»>) prefix).foreachWithIndex((final int index, final «type.boxedName» value) ->
										result[index] = value);
							} else {
								fillArray(result, 0, prefix);
							}
						«ENDIF»
						System.arraycopy(this.array, 0, result, prefixSize, this.array.length);
						return new «diamondName»(result);
					} else {
						throw new SizeOverflowException();
					}
				}
			}

			/**
			 * O(this.size + suffix.size)
			 */
			public «genericName» appendAll(final Iterable<«type.genericBoxedName»> suffix) throws SizeOverflowException {
				if (this.array.length == 0) {
					return ofAll(suffix);
				} else if (suffix instanceof «wildcardName») {
					return concat((«genericName») suffix);
				} else if (suffix instanceof Sized && ((Sized) suffix).hasKnownFixedSize()) {
					return appendSized(suffix, ((Sized) suffix).size());
				} else {
					final «arrayBuilderName» builder;
					if (suffix instanceof Collection<?> && suffix instanceof RandomAccess) {
						final Collection<?> col = (Collection<?>) suffix;
						if (col.isEmpty()) {
							return this;
						} else {
							final int suffixSize = col.size();
							final int size = this.array.length + suffixSize;
							if (size < 0) {
								throw new SizeOverflowException();
							} else {
								builder = builderWithCapacity(size);
								builder.appendArray(this.array);
							}
						}
					} else {
						builder = new «arrayBuilderDiamondName»(this.array, this.array.length);
					}
					if (suffix instanceof «type.containerWildcardName») {
						((«type.containerGenericName») suffix).foreach(builder::append);
					} else {
						suffix.forEach(builder::append);
					}
					return builder.build();
				}
			}

			/**
			 * O(prefix.size + this.size)
			 */
			public «genericName» prependAll(final Iterable<«type.genericBoxedName»> prefix) throws SizeOverflowException {
				if (this.array.length == 0) {
					return ofAll(prefix);
				} else if (prefix instanceof «wildcardName») {
					return ((«genericName») prefix).concat(this);
				} else if (prefix instanceof Sized && ((Sized) prefix).hasKnownFixedSize()) {
					return prependSized(prefix, ((Sized) prefix).size());
				} else {
					final «arrayBuilderName» builder;
					if (prefix instanceof Collection<?> && prefix instanceof RandomAccess) {
						final Collection<?> col = (Collection<?>) prefix;
						if (col.isEmpty()) {
							return this;
						} else {
							final int prefixSize = col.size();
							final int size = prefixSize + this.array.length;
							if (size < 0) {
								throw new SizeOverflowException();
							} else {
								builder = builderWithCapacity(size);
							}
						}
					} else {
						builder = builder();
					}
					if (prefix instanceof «type.containerWildcardName») {
						((«type.containerGenericName») prefix).foreach(builder::append);
					} else {
						prefix.forEach(builder::append);
					}
					builder.appendArray(this.array);
					return builder.build();
				}
			}

			public final «genericName» slice(final int fromIndexInclusive, final int toIndexExclusive) {
				sliceRangeCheck(fromIndexInclusive, toIndexExclusive, this.array.length);
				if (fromIndexInclusive == 0 && toIndexExclusive == this.array.length) {
					return this;
				} else if (fromIndexInclusive == toIndexExclusive) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] result = new «type.javaName»[toIndexExclusive - fromIndexInclusive];
					System.arraycopy(this.array, fromIndexInclusive, result, 0, toIndexExclusive - fromIndexInclusive);
					return new «diamondName»(result);
				}
			}

			public «genericName» reverse() {
				if (this.array.length == 0 || this.array.length == 1) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[this.array.length];
					for (int i = 0; i < this.array.length; i++) {
						result[this.array.length - i - 1] = this.array[i];
					}
					return new «diamondName»(result);
				}
			}

			«IF type == Type.OBJECT»
				public <B> Array<B> map(final F<A, B> f) {
			«ELSE»
				public <A> Array<A> map(final «type.typeName»ObjectF<A> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptyArray();
				«IF type == Type.OBJECT»
					} else if (f == F.id()) {
						return (Array<B>) this;
				«ENDIF»
				} else {
					final Object[] result = new Object[this.array.length];
					for (int i = 0; i < this.array.length; i++) {
						result[i] = requireNonNull(f.apply(«type.genericCast»this.array[i]));
					}
					return new Array<>(result);
				}
			}

			«FOR toType : Type.primitives»
				public «toType.typeName»Array mapTo«toType.typeName»(final «IF type != Type.OBJECT»«type.typeName»«ENDIF»«toType.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
					requireNonNull(f);
					if (isEmpty()) {
						return empty«toType.typeName»Array();
					«IF type == toType»
					} else if (f == «type.javaName»Id()) {
						return this;
					«ENDIF»
					} else {
						final «toType.javaName»[] result = new «toType.javaName»[this.array.length];
						for (int i = 0; i < this.array.length; i++) {
							result[i] = f.apply(«type.genericCast»this.array[i]);
						}
						return new «toType.typeName»Array(result);
					}
				}

			«ENDFOR»
			«IF type == Type.OBJECT»
				public <B> Array<B> mapWithIndex(final IntObjectObjectF2<A, B> f) {
			«ELSE»
				public <A> Array<A> mapWithIndex(final Int«type.typeName»ObjectF2<A> f) {
			«ENDIF»
				if (isEmpty()) {
					return emptyArray();
				} else {
					final Object[] result = new Object[this.array.length];
					for (int i = 0; i < this.array.length; i++) {
						result[i] = requireNonNull(f.apply(i, «IF type == Type.OBJECT»(A) «ENDIF»this.array[i]));
					}
					return new Array<>(result);
				}
			}

			«IF type == Type.OBJECT»
				public <B> Array<B> flatMap(final F<A, Iterable<B>> f) {
			«ELSE»
				public <A> Array<A> flatMap(final «type.typeName»ObjectF<Iterable<A>> f) {
			«ENDIF»
				requireNonNull(f);
				if (isEmpty()) {
					return emptyArray();
				} else {
					«IF type == Type.OBJECT»
						final ArrayBuilder<B> builder = builder();
					«ELSE»
						final ArrayBuilder<A> builder = Array.builder();
					«ENDIF»
					for (final «type.javaName» value : this.array) {
						builder.appendAll(f.apply(«type.genericCast»value));
					}
					return builder.build();
				}
			}

			«FOR toType : Type.primitives»
				«IF type == Type.OBJECT»
					public final «toType.arrayGenericName» flatMapTo«toType.typeName»(final F<A, Iterable<«toType.genericBoxedName»>> f) {
				«ELSE»
					public final «toType.arrayGenericName» flatMapTo«toType.typeName»(final «type.typeName»ObjectF<Iterable<«toType.genericBoxedName»>> f) {
				«ENDIF»
					requireNonNull(f);
					if (isEmpty()) {
						return empty«toType.arrayShortName»();
					} else {
						final «toType.arrayBuilderGenericName» builder = «toType.arrayShortName».builder();
						for (final «type.javaName» value : this.array) {
							builder.appendAll(f.apply(«type.genericCast»value));
						}
						return builder.build();
					}
				}

			«ENDFOR»
			public «genericName» filter(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				if (isEmpty()) {
					return empty«shortName»();
				} else {
					final «arrayBuilderName» builder = builder();
					for (final «type.javaName» value : this.array) {
						if (predicate.apply(«type.genericCast»value)) {
							builder.append(«type.genericCast»value);
						}
					}
					if (builder.size() == this.array.length) {
						return this;
					} else {
						return builder.build();
					}
				}
			}

			«IF type == Type.OBJECT»
				public <B extends A> Array<B> filterByClass(final Class<B> clazz) {
					requireNonNull(clazz);
					return (Array<B>) filter(clazz::isInstance);
				}

			«ENDIF»
			public «genericName» limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return empty«shortName»();
				} else if (n >= this.array.length) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[n];
					System.arraycopy(this.array, 0, result, 0, n);
					return new «diamondName»(result);
				}
			}

			public «genericName» skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n >= this.array.length) {
					return empty«shortName»();
				} else if (n == 0) {
					return this;
				} else {
					final «type.javaName»[] result = new «type.javaName»[this.array.length - n];
					System.arraycopy(this.array, n, result, 0, result.length);
					return new «diamondName»(result);
				}
			}

			public «genericName» takeWhile(final «type.boolFName» predicate) {
				int n = 0;
				for (final «type.javaName» value : this.array) {
					if (predicate.apply(«type.genericCast»value)) {
						n++;
					} else {
						break;
					}
				}
				return limit(n);
			}

			public «genericName» dropWhile(final «type.boolFName» predicate) {
				int n = 0;
				for (final «type.javaName» value : this.array) {
					if (predicate.apply(«type.genericCast»value)) {
						n++;
					} else {
						break;
					}
				}
				return skip(n);
			}

			@Override
			public void forEach(final Consumer<? super «type.genericBoxedName»> action) {
				requireNonNull(action);
				for (final «type.javaName» value : this.array) {
					action.accept(«type.genericCast»value);
				}
			}

			@Override
			public void foreach(final «type.effGenericName» eff) {
				requireNonNull(eff);
				for (final «type.javaName» value : this.array) {
					eff.apply(«type.genericCast»value);
				}
			}

			@Override
			«IF type == Type.OBJECT»
				public void foreachWithIndex(final IntObjectEff2<A> eff) {
			«ELSE»
				public void foreachWithIndex(final Int«type.typeName»Eff2 eff) {
			«ENDIF»
				requireNonNull(eff);
				for (int i = 0; i < this.array.length; i++) {
					eff.apply(i, «type.genericCast»this.array[i]);
				}
			}

			@Override
			public boolean foreachUntil(final «type.boolFName» eff) {
				requireNonNull(eff);
				for (final «type.javaName» value : this.array) {
					if (!eff.apply(«type.genericCast»value)) {
						return false;
					}
				}
				return true;
			}

			@Override
			@Deprecated
			public «type.arrayGenericName» to«type.arrayShortName»() {
				return this;
			}

			«IF type == Type.OBJECT»
				@Override
				public Seq<A> toSeq() {
					if (this.array.length == 0) {
						return Seq.emptySeq();
					} else {
						return Seq.seqFromSharedArray(this.array);
					}
				}
			«ELSE»
				@Override
				public «type.typeName»Seq to«type.typeName»Seq() {
					if (this.array.length == 0) {
						return «type.typeName»Seq.empty«type.typeName»Seq();
					} else {
						return «type.typeName»Seq.seqFromSharedArray(this.array);
					}
				}
			«ENDIF»

			@Override
			public «type.javaName»[] «type.toArrayName»() {
				if (this.array.length == 0) {
					return this.array;
				} else {
					final «type.javaName»[] result = new «type.javaName»[this.array.length];
					System.arraycopy(this.array, 0, result, 0, this.array.length);
					return result;
				}
			}
			«IF type == Type.OBJECT»

				@Override
				public A[] toPreciseArray(final IntObjectF<A[]> supplier) {
					final A[] result = supplier.apply(this.array.length);
					System.arraycopy(this.array, 0, result, 0, this.array.length);
					return result;
				}
			«ENDIF»

			«IF type == Type.OBJECT»
				public Array<A> sort(final Ord<A> ord) {
					requireNonNull(ord);
					if (this.array.length <= 1) {
						return this;
					} else {
						final Object[] sorted = new Object[this.array.length];
						System.arraycopy(this.array, 0, sorted, 0, this.array.length);
						Arrays.sort(sorted, (Ord<Object>) ord);
						return new Array<>(sorted);
					}
				}
			«ELSEIF type == Type.BOOLEAN»
				public «genericName» sortAsc() {
					if (this.array.length <= 1) {
						return this;
					} else {
						int countTrue = 0;
						for (final boolean value : this.array) {
							if (value) {
								countTrue++;
							}
						}
						final boolean[] sorted = new boolean[this.array.length];
						Arrays.fill(sorted, this.array.length - countTrue, this.array.length, true);
						return new BooleanArray(sorted);
					}
				}

				public «genericName» sortDesc() {
					if (this.array.length <= 1) {
						return this;
					} else {
						int countTrue = 0;
						for (final boolean value : this.array) {
							if (value) {
								countTrue++;
							}
						}
						final boolean[] sorted = new boolean[this.array.length];
						Arrays.fill(sorted, 0, countTrue, true);
						return new BooleanArray(sorted);
					}
				}
			«ELSE»
				public «genericName» sortAsc() {
					if (this.array.length <= 1) {
						return this;
					} else {
						final «type.javaName»[] sorted = new «type.javaName»[this.array.length];
						System.arraycopy(this.array, 0, sorted, 0, this.array.length);
						Arrays.sort(sorted);
						return new «diamondName»(sorted);
					}
				}

				public «genericName» sortDesc() {
					if (this.array.length <= 1) {
						return this;
					} else {
						final «type.javaName»[] sorted = new «type.javaName»[this.array.length];
						System.arraycopy(this.array, 0, sorted, 0, this.array.length);
						Arrays.sort(sorted);
						Common.reverse«shortName»(sorted);
						return new «diamondName»(sorted);
					}
				}
			«ENDIF»

			@Override
			public «type.iteratorGenericName» iterator() {
				«IF type.javaUnboxedType»
					return isEmpty() ? «type.noneName»().iterator() : new «shortName»Iterator(this.array);
				«ELSE»
					return isEmpty() ? emptyIterator() : new «shortName»Iterator«IF type == Type.OBJECT»<>«ENDIF»(this.array);
				«ENDIF»
			}

			@Override
			public «type.iteratorGenericName» reverseIterator() {
				«IF type.javaUnboxedType»
					return isEmpty() ? «type.noneName»().iterator() : new «shortName»ReverseIterator(this.array);
				«ELSE»
					return isEmpty() ? emptyIterator() : new «shortName»ReverseIterator«IF type == Type.OBJECT»<>«ENDIF»(this.array);
				«ENDIF»
			}

			@Override
			«IF type == Type.OBJECT»
				public Spliterator<A> spliterator() {
			«ELSEIF type == Type.BOOLEAN»
				public Spliterator<Boolean> spliterator() {
			«ELSE»
				public Spliterator.Of«type.typeName» spliterator() {
			«ENDIF»
				return Spliterators.spliterator(«IF type == Type.BOOLEAN»new BooleanArrayIterator(this.array), size()«ELSE»this.array«ENDIF», Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE);
			}

			@Override
			public int hashCode() {
				return Arrays.hashCode(this.array);
			}

			«indexedEquals(type)»

			public boolean isStrictlyEqualTo(final «genericName» other) {
				if (other == this) {
					return true;
				} else {
					return Arrays.equals(this.array, other.array);
				}
			}

			@Override
			public String toString() {
				return Arrays.toString(this.array);
			}

			«transform(genericName)»

			public static «paramGenericName» empty«shortName»() {
				«IF type == Type.OBJECT»
					return («genericName») EMPTY;
				«ELSE»
					return EMPTY;
				«ENDIF»
			}

			public static «paramGenericName» single«shortName»(final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				return new «diamondName»(new «type.javaName»[] { value });
			}

			static «paramGenericName» create(final «type.javaName»[] array) {
				if (array.length == 0) {
					return empty«shortName»();
				} else {
					return new «diamondName»(array);
				}
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» «shortName.firstToLowerCase»(final «type.genericName»... values) {
				if (values.length == 0) {
					return empty«shortName»();
				} else {
					«IF type == Type.OBJECT»
						for (final Object a : values) {
							requireNonNull(a);
						}
					«ENDIF»
					final «type.javaName»[] array = new «type.javaName»[values.length];
					System.arraycopy(values, 0, array, 0, values.length);
					return new «diamondName»(array);
				}
			}

			«javadocSynonym(shortName.firstToLowerCase)»
			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» of(final «type.genericName»... values) {
				return «shortName.firstToLowerCase»(values);
			}

			«IF type == Type.OBJECT»
				public static <A extends Comparable<A>> Array<A> sortAsc(final Array<A> array) {
					return array.sort(asc());
				}

				public static <A extends Comparable<A>> Array<A> sortDesc(final Array<A> array) {
					return array.sort(desc());
				}

			«ENDIF»
			public static «paramGenericName» repeat(final int size, final «type.genericName» value) {
				«IF type == Type.OBJECT»
					requireNonNull(value);
				«ENDIF»
				if (size < 0) {
					throw new IllegalArgumentException(Integer.toString(size));
				} else if (size == 0) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] array = new «type.javaName»[size];
					Arrays.fill(array, value);
					return new «diamondName»(array);
				}
			}

			«fill(type, paramGenericName)»

			«fillUntil(type, paramGenericName, arrayBuilderName, "append")»

			public static «paramGenericName» tabulate(final int size, final Int«type.typeName»F«IF type == Type.OBJECT»<A>«ENDIF» f) {
				requireNonNull(f);
				if (size < 0) {
					throw new IllegalArgumentException(Integer.toString(size));
				} else if (size == 0) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] array = new «type.javaName»[size];
					for (int i = 0; i < size; i++) {
						«IF type == Type.OBJECT»
							array[i] = requireNonNull(f.apply(i));
						«ELSE»
							array[i] = f.apply(i);
						«ENDIF»
					}
					return new «diamondName»(array);
				}
			}

			«iterateWhile(type, paramGenericName, arrayBuilderName)»

			«iterateUntil(type, paramGenericName, arrayBuilderName)»

			private static «paramGenericName» sizedToArray(final Iterable<«type.genericBoxedName»> iterable, final int size) {
				if (size == 0) {
					return empty«shortName»();
				} else {
					final «type.javaName»[] array = new «type.javaName»[size];
					«IF type == Type.OBJECT»
						fillArray(array, 0, iterable);
					«ELSE»
						if (iterable instanceof Container<?>) {
							((Container<«type.boxedName»>) iterable).foreachWithIndex((final int index, final «type.boxedName» value) -> array[index] = value);
						} else {
							fillArray(array, 0, iterable);
						}
					«ENDIF»
					return new «diamondName»(array);
				}
			}

			public static «paramGenericName» ofAll(final Iterable<«type.genericBoxedName»> iterable) {
				if (iterable instanceof «type.containerWildcardName») {
					return ((«type.containerGenericName») iterable).to«type.arrayShortName»();
				} else if (iterable instanceof Sized && ((Sized) iterable).hasKnownFixedSize()) {
					return sizedToArray(iterable, ((Sized) iterable).size());
				«IF type == Type.OBJECT»
					} else if (iterable instanceof Collection<?>) {
						final Object[] array = ((Collection<?>) iterable).toArray();
						if (array.length == 0) {
							return emptyArray();
						} else {
							for (final Object value : array) {
								requireNonNull(value);
							}
							return new Array<>(array);
						}
				«ENDIF»
				} else {
					final «arrayBuilderName» builder = builder();
					iterable.forEach(builder::append);
					return builder.build();
				}
			}

			public static «paramGenericName» fromIterator(final Iterator<«type.genericBoxedName»> iterator) {
				requireNonNull(iterator);
				final «arrayBuilderName» builder = builder();
				builder.appendIterator(iterator);
				return builder.build();
			}

			public static «paramGenericName» from«type.streamName»(final «type.streamGenericName» stream) {
				final «arrayBuilderName» builder = builder();
				builder.append«type.streamName»(stream);
				return builder.build();
			}

			«IF type == Type.OBJECT»
				«FOR arity : 2 .. Constants.MAX_PRODUCT_ARITY»
					public static <«(1..arity).map['''A«it», '''].join»B> Array<B> map«arity»(«(1..arity).map['''final Array<A«it»> array«it», '''].join»final F«arity»<«(1..arity).map['''A«it», '''].join»B> f) {
						requireNonNull(f);
						if («(1 .. arity).map["array" + it + ".isEmpty()"].join(" || ")») {
							return emptyArray();
						} else {
							«FOR i : 1 .. arity»
								final Object[] arr«i» = array«i».array;
							«ENDFOR»
							final long size1 = arr1.length;
							«FOR i : 2 .. arity»
								final long size«i» = size«i-1» * arr«i».length;
								if (size«i» != (int) size«i») {
									throw new SizeOverflowException();
								}
							«ENDFOR»
							final Object[] array = new Object[(int) size«arity»];
							int i = 0;
							«FOR i : 1 .. arity»
								«(1 ..< i).map["\t"].join»for (final Object a«i» : arr«i») {
							«ENDFOR»
								«(1 ..< arity).map["\t"].join»array[i++] = requireNonNull(f.apply(«(1 .. arity).map['''(A«it») a«it»'''].join(", ")»));
							«FOR i : 1 .. arity»
								«(1 ..< arity - i + 1).map["\t"].join»}
							«ENDFOR»
							return new Array<>(array);
						}
					}

				«ENDFOR»
			«ENDIF»
			«flattenCollection(type, genericName, type.arrayBuilderGenericName)»

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			public static «paramGenericName» concat(final «genericName»... arrays) throws SizeOverflowException {
				if (arrays.length == 0) {
					return empty«shortName»();
				} else if (arrays.length == 1) {
					return requireNonNull(arrays[0]);
				} else if (arrays.length == 2) {
					return arrays[0].concat(arrays[1]);
				} else {
					int size = 0;
					for (final «genericName» array : arrays) {
						size += array.array.length;
						if (size < 0) {
							throw new SizeOverflowException();
						}
					}
					if (size == 0) {
						return empty«shortName»();
					} else {
						final «type.javaName»[] result = new «type.javaName»[size];
						int pos = 0;
						for (final «genericName» array : arrays) {
							System.arraycopy(array.array, 0, result, pos, array.array.length);
							pos += array.array.length;
						}
						return new «diamondName»(result);
					}
				}
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»«arrayBuilderName» builder() {
				return new «arrayBuilderDiamondName»(«type.emptyArrayName», 0);
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»«arrayBuilderName» builderWithCapacity(final int initialCapacity) {
				if (initialCapacity == 0) {
					return builder();
				} else {
					return new «arrayBuilderDiamondName»(new «type.javaName»[initialCapacity], 0);
				}
			}

			public static «IF type == Type.OBJECT»<A> «ENDIF»Collector<«type.genericBoxedName», ?, «genericName»> collector() {
				«IF type == Type.OBJECT»
					return Collector.<«type.genericBoxedName», «type.arrayBuilderGenericName», «genericName»> of(
				«ELSE»
					return Collector.of(
				«ENDIF»
					«shortName»::builder, «type.arrayBuilderShortName»::append, «type.arrayBuilderShortName»::appendArrayBuilder, «type.arrayBuilderShortName»::build);
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
	''' }
}
