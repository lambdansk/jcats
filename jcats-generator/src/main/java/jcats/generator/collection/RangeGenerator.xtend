package jcats.generator.collection

import java.util.List
import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.Type

final class RangeGenerator implements ClassGenerator {

	def static List<Generator> generators() {
		Type.values.toList.map[new ArrayGenerator(it) as Generator]
	}

	override className() { Constants.RANGE }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.Serializable;
		import java.util.NoSuchElementException;
		import java.util.PrimitiveIterator;
		import java.util.Spliterator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».IntOption.*;
		import static «Constants.COMMON».*;
		import static «Constants.COLLECTION».IntArray.*;
		import static «Constants.COLLECTION».IntIndexedContainerView.*;

		final class Range implements IntIndexedContainerView, Serializable {

			private final int low;
			private final int high;
			private final boolean closed;

			Range(final int low, final int high, final boolean closed) {
				this.low = low;
				this.high = high;
				this.closed = closed;
			}

			@Override
			public int size() throws SizeOverflowException {
				final long size = longSize();
				if (size == (int) size) {
					return (int) size;
				} else {
					throw new SizeOverflowException();
				}
			}

			@Override
			public boolean isEmpty() {
				return false;
			}

			@Override
			public boolean isNotEmpty() {
				return true;
			}

			@Override
			public boolean hasKnownFixedSize() {
				final long size = longSize();
				return (size == (int) size);
			}

			private long longSize() {
				return (long) this.high - this.low + (this.closed ? 1 : 0);
			}

			@Override
			public int get(final int index) throws IndexOutOfBoundsException {
				if (index < 0) {
					«indexOutOfBounds»
				} else {
					final int result = this.low + index;
					if (result >= this.low &&
							(this.closed && result <= this.high ||
							!this.closed && result < this.high)) {
						return result;
					} else {
						«indexOutOfBounds»
					}
				}
			}

			@Override
			public int first() {
				return this.low;
			}

			@Override
			public IntOption findFirst() {
				return intSome(this.low);
			}

			@Override
			public int last() throws NoSuchElementException {
				if (this.closed) {
					return this.high;
				} else {
					return this.high - 1;
				}
			}

			@Override
			public IntOption findLast() {
				if (this.closed) {
					return intSome(this.high);
				} else {
					return intSome(this.high - 1);
				}
			}

			@Override
			public boolean contains(final int value) {
				return (value >= this.low) && (this.closed ? value <= this.high : value < this.high);
			}

			@Override
			public IntOption indexOf(final int value) {
				if (value >= this.low &&
						(this.closed && value <= this.high ||
						!this.closed && value < this.high)) {
					final int index = value - this.low;
					if (index < 0) {
						throw new SizeOverflowException();
					} else {
						return intSome(index);
					}
				} else {
					return intNone();
				}
			}

			@Override
			public IntOption lastIndexOf(final int value) {
				return indexOf(value);
			}

			@Override
			public IntIndexedContainerView slice(final int fromIndexInclusive, final int toIndexExclusive) {
				final long size = longSize();
				if (size == (int) size) {
					sliceRangeCheck(fromIndexInclusive, toIndexExclusive, (int) size);
				} else {
					sliceRangeCheck(fromIndexInclusive, toIndexExclusive);
				}
				if (fromIndexInclusive == 0 && toIndexExclusive == size) {
					return this;
				} else if (fromIndexInclusive == toIndexExclusive) {
					return emptyIntArray().view();
				} else {
					return new Range(fromIndexInclusive, toIndexExclusive, false);
				}
			}

			@Override
			public IntIndexedContainerView limit(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return emptyIntIndexedContainerView();
				} else {
					final long upTo = (long) this.low + n;
					if (upTo != (int) upTo ||
							this.closed && upTo >= this.high+1L ||
							!this.closed && upTo >= this.high) {
						return this;
					} else {
						return new Range(this.low, (int) upTo, false);
					}
				}
			}

			@Override
			public IntIndexedContainerView skip(final int n) {
				if (n < 0) {
					throw new IllegalArgumentException(Integer.toString(n));
				} else if (n == 0) {
					return this;
				} else {
					final long from = (long) this.low + n;
					if (from != (int) from ||
							this.closed && from >= this.high+1L ||
							!this.closed && from >= this.high) {
						return emptyIntArray().view();
					} else {
						return new Range((int) from, this.high, this.closed);
					}
				}
			}

			@Override
			public void foreach(final IntEff eff) {
				requireNonNull(eff);
				for (int i = this.low; i < this.high; i++) {
					eff.apply(i);
				}
				if (this.closed) {
					eff.apply(this.high);
				}
			}

			@Override
			public void foreachWithIndex(final IntIntEff2 eff) {
				requireNonNull(eff);
				if (hasKnownFixedSize()) {
					int index = 0;
					for (int i = this.low; i < this.high; i++, index++) {
						eff.apply(index, i);
					}
					if (this.closed) {
						eff.apply(index, this.high);
					}
				} else {
					throw new SizeOverflowException();
				}
			}

			@Override
			public boolean foreachUntil(final IntBooleanF eff) {
				requireNonNull(eff);
				for (int i = this.low; i < this.high; i++) {
					if (!eff.apply(i)) {
						return false;
					}
				}
				if (this.closed) {
					if (!eff.apply(this.high)) {
						return false;
					}
				}
				return true;
			}

			@Override
			public PrimitiveIterator.OfInt iterator() {
				if (this.closed) {
					return new ClosedRangeIterator(this.low, this.high);
				} else {
					return new RangeIterator(this.low, this.high);
				}
			}

			@Override
			public PrimitiveIterator.OfInt reverseIterator() {
				if (this.closed) {
					return new ClosedRangeReverseIterator(this.low, this.high);
				} else {
					return new RangeReverseIterator(this.low, this.high);
				}
			}

			@Override
			public boolean isReverseQuick() {
				return true;
			}

			@Override
			public IntOption max() {
				if (this.closed) {
					return intSome(this.high);
				} else {
					return intSome(this.high - 1);
				}
			}

			@Override
			public IntOption min() {
				return intSome(this.low);
			}

			@Override
			public int sum() {
				final long a1 = this.low;
				final long a2 = this.closed ? this.high : this.high - 1;
				final long n = a2 - a1 + 1;
				return (int) ((a1 + a2) * n / 2);
			}

			@Override
			public int spliteratorCharacteristics() {
				return Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED | Spliterator.NONNULL | Spliterator.IMMUTABLE;
			}

			@Override
			public IntStream2 stream() {
				if (this.closed) {
					return IntStream2.rangeClosed(this.low, this.high);
				} else {
					return IntStream2.range(this.low, this.high);
				}
			}

			@Override
			public IntStream2 parallelStream() {
				return stream().parallel();
			}

			@Override
			public Spliterator.OfInt spliterator() {
				return stream().spliterator();
			}

			@Override
			public IntIndexedContainerView sortAsc() {
				return this;
			}

			@Override
			public IntIndexedContainerView sortDesc() {
				return reverse();
			}

			«orderedHashCode(Type.INT)»

			@Override
			public boolean equals(final Object obj) {
				if (obj == this) {
					return true;
				} else if (obj instanceof Range) {
					final Range other = (Range) obj;
					if (this.low == other.low) {
						final long high1 = this.closed ? this.high + 1L : this.high;
						final long high2 = other.closed ? other.high + 1L : other.high;
						return (high1 == high2);
					} else {
						return false;
					}
				} else if (obj instanceof IntIndexedContainer) {
					return intIndexedContainersEqual(this, (IntIndexedContainer) obj);
				} else {
					return false;
				}
			}

			«toStr(Type.INT)»
		}

		final class RangeIterator implements PrimitiveIterator.OfInt {

			private int i;
			private final int high;

			RangeIterator(final int low, final int high) {
				this.i = low;
				this.high = high;
			}

			@Override
			public boolean hasNext() {
				return (this.i < this.high);
			}

			@Override
			public int nextInt() {
				if (this.i < this.high) {
					return this.i++;
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class ClosedRangeIterator implements PrimitiveIterator.OfInt {

			private int i;
			private final int high;
			private boolean hasNext;

			ClosedRangeIterator(final int low, final int high) {
				this.i = low;
				this.high = high;
				this.hasNext = true;
			}

			@Override
			public boolean hasNext() {
				return this.hasNext;
			}

			@Override
			public int nextInt() {
				if (this.hasNext) {
					if (this.i < this.high) {
						return this.i++;
					} else {
						this.hasNext = false;
						return this.i;
					}
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class RangeReverseIterator implements PrimitiveIterator.OfInt {

			private int i;
			private final int low;

			RangeReverseIterator(final int low, final int high) {
				this.i = high;
				this.low = low;
			}

			@Override
			public boolean hasNext() {
				return (this.i > this.low);
			}

			@Override
			public int nextInt() {
				if (this.i > this.low) {
					return --this.i;
				} else {
					throw new NoSuchElementException();
				}
			}
		}

		final class ClosedRangeReverseIterator implements PrimitiveIterator.OfInt {

			private int i;
			private final int low;
			private boolean hasNext;

			ClosedRangeReverseIterator(final int low, final int high) {
				this.i = high;
				this.low = low;
				this.hasNext = true;
			}

			@Override
			public boolean hasNext() {
				return this.hasNext;
			}

			@Override
			public int nextInt() {
				if (this.hasNext) {
					if (this.i > this.low) {
						return this.i--;
					} else {
						this.hasNext = false;
						return this.i;
					}
				} else {
					throw new NoSuchElementException();
				}
			}
		}
	''' }
}
