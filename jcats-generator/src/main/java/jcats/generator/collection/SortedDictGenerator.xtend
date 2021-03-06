package jcats.generator.collection

import jcats.generator.ClassGenerator
import jcats.generator.Constants
import jcats.generator.Type

final class SortedDictGenerator implements ClassGenerator {
	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { "SortedDict" }
	def genericName() { "SortedDict<K, A>" }
	def paramGenericName() { "<K, A> SortedDict<K, A>" }
	def diamondName() { "SortedDict<>" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.io.PrintWriter;
		import java.io.StringWriter;
		import java.io.Serializable;
		import java.util.ArrayList;
		import java.util.Collections;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.List;
		import java.util.Map;
		import java.util.NoSuchElementException;
		import java.util.SortedMap;
		import java.util.Spliterator;
		import java.util.function.Consumer;
		import java.util.stream.Stream;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static java.util.Collections.emptyIterator;
		import static «Constants.JCATS».Order.*;
		import static «Constants.JCATS».Ord.*;
		import static «Constants.OPTION».*;
		import static «Constants.P».p;
		import static «Constants.COMMON».*;
		import static «Constants.STACK».*;
		import static «Constants.SORTED_DICT».*;
		import static «Constants.COLLECTION».AVLCommon.*;

		public final class SortedDict<K, @Covariant A> implements SortedKeyValue<K, A>, Serializable {
			static final SortedDict<?, ?> EMPTY =
					new SortedDict<>(null, null, null, Ord.<Integer>asc(), 0);
			static final SortedDict<?, ?> EMPTY_REVERSED =
					new SortedDict<>(null, null, null, Ord.<Integer>desc(), 0);

			final P<K, A> entry;
			final SortedDict<K, A> left;
			final SortedDict<K, A> right;
			private final int size;
			final Ord<K> ord;
			private final int balance;

			private SortedDict(final P<K, A> entry, final SortedDict<K, A> left, final SortedDict<K, A> right, final Ord<K> ord, final int balance) {
				this.entry = entry;
				this.left = left;
				this.right = right;
				if (entry == null) {
					this.size = 0;
				} else {
					this.size = ((left == null) ? 0 : left.size) + ((right == null) ? 0 : right.size) + 1;
				}
				this.ord = ord;
				this.balance = balance;
			}

			@Override
			public Ord<K> ord() {
				return this.ord;
			}

			@Override
			public A getOrNull(final K key) {
				requireNonNull(key);
				if (this.entry == null) {
					return null;
				} else {
					return search(this, key);
				}
			}

			static <K, A> A search(«genericName» dict, final K key) {
				final Ord<K> ord = dict.ord;
				while (true) {
					final Order order = ord.order(key, dict.entry.get1());
					if (order == EQ) {
						return dict.entry.get2();
					} else if (order == LT) {
						if (dict.left == null) {
							return null;
						} else {
							dict = dict.left;
						}
					} else if (order == GT) {
						if (dict.right == null) {
							return null;
						} else {
							dict = dict.right;
						}
					} else {
						throw nullOrder(order);
					}
				}
			}

			public SortedDict<K, A> put(final K key, final A value) {
				requireNonNull(key);
				requireNonNull(value);

				if (this.entry == null) {
					return new SortedDict<>(p(key, value), null, null, this.ord, 0);
				} else {
					return update(key, value, null, new InsertResult());
				}
			}

			public SortedDict<K, A> putEntry(final P<K, A> entry) {
				requireNonNull(entry);

				if (this.entry == null) {
					return new SortedDict<>(entry, null, null, this.ord, 0);
				} else {
					return update(entry.get1(), entry.get2(), entry, new InsertResult());
				}
			}

			public SortedDict<K, A> updateValue(final K key, final F<A, A> f) {
				requireNonNull(key);
				requireNonNull(f);

				if (this.entry == null) {
					return this;
				} else {
					return replaceValue(key, f);
				}
			}

			public SortedDict<K, A> updateValueOrPut(final K key, final A defaultValue, final F<A, A> f) {
				requireNonNull(key);
				requireNonNull(defaultValue);
				requireNonNull(f);

				if (this.entry == null) {
					return new SortedDict<>(p(key, defaultValue), null, null, this.ord, 0);
				} else if (containsKey(key)) {
					return replaceValue(key, f);
				} else {
					return update(key, defaultValue, null, new InsertResult());
				}
			}

			private «genericName» update(final K key, final A value, final P<K, A> entry, final InsertResult result) {
				«AVLCommonGenerator.update(genericName, diamondName, "key", "entry.get1()", "(entry == null) ? p(key, value) : entry",
					"key == this.entry.get1() && value == this.entry.get2()", "key, value, entry")»
			}

			«AVLCommonGenerator.insertAndRotateRight(genericName, diamondName)»

			«AVLCommonGenerator.insertAndRotateLeft(genericName, diamondName)»

			private SortedDict<K, A> replaceValue(final K key, final F<A, A> f) {
				final Order order = this.ord.order(key, this.entry.get1());
				if (order == EQ) {
					final A newValue = requireNonNull(f.apply(this.entry.get2()));
					if (newValue == this.entry.get2()) {
						return this;
					} else {
						return new SortedDict<>(p(key, newValue), this.left, this.right, this.ord, this.balance);
					}
				} else if (order == LT) {
					if (this.left == null) {
						return this;
					} else {
						final SortedDict<K, A> newLeft = this.left.replaceValue(key, f);
						if (newLeft == this.left) {
							return this;
						} else {
							return new SortedDict<>(this.entry, newLeft, this.right, this.ord, this.balance);
						}
					}
				} else if (order == GT) {
					if (this.right == null) {
						return this;
					} else {
						final SortedDict<K, A> newRight = this.right.replaceValue(key, f);
						if (newRight == this.right) {
							return this;
						} else {
							return new SortedDict<>(this.entry, this.left, newRight, this.ord, this.balance);
						}
					}
				} else {
					throw nullOrder(order);
				}
			}

			public SortedDict<K, A> remove(final K key) {
				requireNonNull(key);
				if (this.entry == null) {
					return this;
				} else {
					final SortedDict<K, A> newDict = delete(key, new DeleteResult<>());
					if (newDict == null) {
						return emptySortedDictBy(this.ord);
					} else {
						return newDict;
					}
				}
			}

			private SortedDict<K, A> delete(final K key, final DeleteResult<K, A> result) {
				«AVLCommonGenerator.delete(genericName, diamondName, "key", "entry.get1()")»
			}

			«AVLCommonGenerator.deleteMinimum(genericName, diamondName, "DeleteResult<K, A>")»

			«AVLCommonGenerator.deleteMaximum(genericName, diamondName, "DeleteResult<K, A>")»

			«AVLCommonGenerator.deleteAndRotateLeft(genericName, diamondName, "P<K, A>", "DeleteResult<K, A>")»

			«AVLCommonGenerator.deleteAndRotateRight(genericName, diamondName, "DeleteResult<K, A>")»

			@Override
			public P<K, A> first() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return getFirst(this);
				}
			}

			@Override
			public Option<P<K, A>> findFirst() {
				if (isEmpty()) {
					return none();
				} else {
					return some(getFirst(this));
				}
			}

			@Override
			public P<K, A> last() throws NoSuchElementException {
				if (isEmpty()) {
					throw new NoSuchElementException();
				} else {
					return getLast(this);
				}
			}

			@Override
			public Option<P<K, A>> findLast() {
				if (isEmpty()) {
					return none();
				} else {
					return some(getLast(this));
				}
			}

			private static <K, A> P<K, A> getFirst(«genericName» dict) {
				«AVLCommonGenerator.getFirstOrLast("dict", "left")»
			}

			private static <K, A> P<K, A> getLast(«genericName» dict) {
				«AVLCommonGenerator.getFirstOrLast("dict", "right")»
			}

			public «genericName» init() throws NoSuchElementException {
				«AVLCommonGenerator.initOrTail(genericName, shortName, "DeleteResult<>", "deleteMaximum")»
			}

			public «genericName» tail() throws NoSuchElementException {
				«AVLCommonGenerator.initOrTail(genericName, shortName, "DeleteResult<>", "deleteMinimum")»
			}

			public «genericName» slice(final K from, final boolean fromInclusive, final K to, final boolean toInclusive) {
				checkRange(this.ord, from, to);
				final SortedDictBuilder<K, A> builder = new SortedDictBuilder<>(this.ord);
				new SlicedSortedDictView<>(this, from, true, fromInclusive, to, true, toInclusive).forEach(builder::putEntry);
				return builder.build();
			}

			public «genericName» sliceFrom(final K from, final boolean inclusive) {
				final SortedDictBuilder<K, A> builder = new SortedDictBuilder<>(this.ord);
				new SlicedSortedDictView<>(this, from, true, inclusive, null, false, false).forEach(builder::putEntry);
				return builder.build();
			}

			public «genericName» sliceTo(final K to, final boolean inclusive) {
				final SortedDictBuilder<K, A> builder = new SortedDictBuilder<>(this.ord);
				new SlicedSortedDictView<>(this, null, false, false, to, true, inclusive).forEach(builder::putEntry);
				return builder.build();
			}

			public «genericName» reverse() {
				final SortedDictBuilder<K, A> builder = new SortedDictBuilder<>(this.ord.reversed());
				builder.putAll(this);
				return builder.build();
			}

			private «genericName» merge(final «genericName» other, final F3<K, A, A, A> mergeFunction) {
				requireNonNull(other);
				if (isEmpty()) {
					return other;
				} else if (other.isEmpty()) {
					return this;
				} else if (size() >= other.size()) {
					«genericName» result = this;
					for (final P<K, A> p : other) {
						final K key = p.get1();
						final A value2 = p.get2();
						result = result.updateValueOrPut(key, value2, value1 -> mergeFunction.apply(key, value1, value2));
					}
					return result;
				} else {
					«genericName» result = other;
					for (final P<K, A> p : this) {
						final K key = p.get1();
						final A value1 = p.get2();
						result = result.updateValueOrPut(key, value1, value2 -> mergeFunction.apply(key, value1, value2));
					}
					return result;
				}
			}

			@Override
			@Deprecated
			public SortedDict<K, A> toSortedDict() {
				return this;
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return (this.entry == null) ? Collections.emptyIterator() : new SortedDictIterator<>(this);
			}

			@Override
			public Iterator<P<K, A>> reverseIterator() {
				return (this.entry == null) ? Collections.emptyIterator() : new SortedDictReverseIterator<>(this);
			}

			@Override
			public void forEach(final Consumer<? super P<K, A>> action) {
				if (this.entry != null) {
					traverse(action);
				}
			}

			void traverse(final Consumer<? super P<K, A>> action) {
				if (this.left != null) {
					this.left.traverse(action);
				}
				action.accept(this.entry);
				if (this.right != null) {
					this.right.traverse(action);
				}
			}

			@Override
			public int size() {
				return this.size;
			}

			@Override
			public SortedKeyValueView<K, A> view() {
				if (isEmpty()) {
					if (this.ord == asc()) {
						return (SortedKeyValueView<K, A>) SortedDictView.EMPTY;
					} else if (this.ord == desc()) {
						return (SortedKeyValueView<K, A>) SortedDictView.EMPTY_REVERSED;
					}
				}
				return new SortedDictView<>(this);
			}

			int checkHeight() {
				final int leftHeight = (this.left == null) ? 0 : this.left.checkHeight();
				final int rightHeight = (this.right == null) ? 0 : this.right.checkHeight();
				if (Math.abs(rightHeight - leftHeight) <= 1) {
					return 1 + Math.max(leftHeight, rightHeight);
				} else {
					throw new AssertionError(String.format("Wrong balance for node %s: left height = %d, right height = %d",
							this.entry, leftHeight, rightHeight));
				}
			}

			private static <K, A> String printNode(final SortedDict<K, A> root) {
				final int maxLevel = maxLevel(root);

				StringWriter sw = new StringWriter();
				try (PrintWriter writer = new PrintWriter(sw)) {
					writer.println();
					printNodeInternal(writer, Collections.singletonList(root), 1, maxLevel);
				}
				return sw.toString();
			}

			private static <K, A> void printNodeInternal(final PrintWriter writer, final List<SortedDict<K, A>> nodes, final int level, final int maxLevel) {
				if (nodes.isEmpty() || isAllElementsNull(nodes)) {
					return;
				}

				final int floor = maxLevel - level;
				final int endgeLines = (int) Math.pow(2, (Math.max(floor - 1, 0)));
				final int firstSpaces = (int) Math.pow(2, (floor)) - 1;
				final int betweenSpaces = (int) Math.pow(2, (floor + 1)) - 1;

				printWhitespaces(writer, firstSpaces);

				final List<SortedDict<K, A>> newNodes = new ArrayList<>();
				for (final SortedDict<K, A> node : nodes) {
					if (node != null) {
						writer.print(node.entry == null ? "null" : node.entry.get1());
						newNodes.add(node.left);
						newNodes.add(node.right);
					} else {
						newNodes.add(null);
						newNodes.add(null);
						writer.print(" ");
					}

					printWhitespaces(writer, betweenSpaces);
				}
				writer.println("");

				for (int i = 1; i <= endgeLines; i++) {
					for (final SortedDict<K, A> node : nodes) {
						printWhitespaces(writer, firstSpaces - i);
						if (node == null) {
							printWhitespaces(writer, endgeLines + endgeLines + i + 1);
							continue;
						}

						if (node.left != null)
							writer.print("/");
						else
							printWhitespaces(writer, 1);

						printWhitespaces(writer, i + i - 1);

						if (node.right != null)
							writer.print("\\");
						else
							printWhitespaces(writer, 1);

						printWhitespaces(writer, endgeLines + endgeLines - i);
					}

					writer.println("");
				}

				printNodeInternal(writer, newNodes, level + 1, maxLevel);
			}

			private static void printWhitespaces(final PrintWriter writer, final int count) {
				for (int i = 0; i < count; i++) {
					writer.print(" ");
				}
			}

			private static <K, A> int maxLevel(final SortedDict<K, A> node) {
				if (node == null || node.entry == null)
					return 0;

				return Math.max(maxLevel(node.left), maxLevel(node.right)) + 1;
			}

			private static <T> boolean isAllElementsNull(final List<T> list) {
				for (final Object object : list) {
					if (object != null)
						return false;
				}

				return true;
			}

			«keyValueEquals»

			«keyValueHashCode»

			«keyValueToString»

			«transform(genericName)»

			public static <K extends Comparable<K>, A> SortedDict<K, A> emptySortedDict() {
				return (SortedDict<K, A>) EMPTY;
			}

			public static <K, A> SortedDict<K, A> emptySortedDictBy(final Ord<K> ord) {
				requireNonNull(ord);
				if (ord == asc()) {
					return (SortedDict<K, A>) EMPTY;
				} else if (ord == desc()) {
					return (SortedDict<K, A>) EMPTY_REVERSED;
				} else {
					return new SortedDict<>(null, null, null, ord, 0);
				}
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> sortedDict(final K key, final A value) {
				return new SortedDict<>(p(key, value), null, null, asc(), 0);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				public static <K extends Comparable<K>, A> SortedDict<K, A> sortedDict(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return sortedDict(key1, value1)
						«FOR j : 2 .. i»
							.put(key«j», value«j»)«IF j == i»;«ENDIF»
						«ENDFOR»
				}

			«ENDFOR»
			«javadocSynonym("emptySortedDict")»
			public static <K extends Comparable<K>, A> SortedDict<K, A> of() {
				return emptySortedDict();
			}

			«javadocSynonym("sortedDict")»
			public static <K extends Comparable<K>, A> SortedDict<K, A> of(final K key, final A value) {
				return sortedDict(key, value);
			}

			«FOR i : 2 .. Constants.DICT_FACTORY_METHODS_COUNT»
				«javadocSynonym("sortedDict")»
				public static <K extends Comparable<K>, A> SortedDict<K, A> of(«(1..i).map["final K key" + it + ", final A value" + it].join(", ")») {
					return sortedDict(«(1..i).map["key" + it + ", value" + it].join(", ")»);
				}

			«ENDFOR»
			@SafeVarargs
			public static <K extends Comparable<K>, A> SortedDict<K, A> ofEntries(final P<K, A>... entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putEntries(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> ofAll(final Iterable<P<K, A>> entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putAll(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> fromIterator(final Iterator<P<K, A>> entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putIterator(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> fromStream(final Stream<P<K, A>> entries) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putStream(entries);
				return builder.build();
			}

			public static <K extends Comparable<K>, A> SortedDict<K, A> fromMap(final Map<K, A> map) {
				final SortedDictBuilder<K, A> builder = builder();
				builder.putMap(map);
				return builder.build();
			}

			public static <K, A> SortedDict<K, A> fromSortedMap(final SortedMap<K, A> map) {
				final Comparator<? super K> comparator = map.comparator();
				final SortedDictBuilder<K, A> builder;
				if (comparator == null) {
					builder = (SortedDictBuilder<K, A>) builder();
				} else {
					builder = builderBy(Ord.cast(Ord.fromComparator(comparator)));
				}
				builder.putMap(map);
				return builder.build();
			}

			@SafeVarargs
			public static «paramGenericName» merge(final F3<K, A, A, A> mergeFunction, final «genericName» dict, final «genericName»... dicts) {
				requireNonNull(mergeFunction);
				requireNonNull(dict);
				if (dicts.length == 0) {
					return dict;
				} else {
					for (final «genericName» d : dicts) {
						if (dict.ord != d.ord) {
							throw new IllegalArgumentException("All instances of «shortName» must have the same Ord");
						}
					}
					«genericName» result = dict;
					for (final «genericName» d : dicts) {
						result = result.merge(d, mergeFunction);
					}
					return result;
				}
			}

			@SafeVarargs
			public static «paramGenericName» mergeUnique(final «genericName» dict, final «genericName»... dicts) throws IllegalStateException {
				return merge((final K key, final A value1, final A value2) -> {
					final String msg = String.format("Duplicate key %s (attempted merging values %s and %s)", key, value1, value2);
					throw new IllegalStateException(msg);
				}, dict, dicts);
			}

			public static <K extends Comparable<K>, A> SortedDictBuilder<K, A> builder() {
				return new SortedDictBuilder<>();
			}

			public static <K, A> SortedDictBuilder<K, A> builderBy(final Ord<K> ord) {
				return new SortedDictBuilder<>(ord);
			}

			«cast(#["K", "A"], #[], #["A"])»

			static final class InsertResult {
				boolean heightIncreased;
			}

			static final class DeleteResult<K, A> {
				P<K, A> entry;
				boolean heightDecreased;
			}
		}

		final class SortedDictIterator<K, A> implements Iterator<P<K, A>> {
			«AVLCommonGenerator.iterator(genericName, "dict", "SortedDictIterator", "P<K, A>", "next", false)»
		}

		final class SortedDictReverseIterator<K, A> implements Iterator<P<K, A>> {
			«AVLCommonGenerator.iterator(genericName, "dict", "SortedDictReverseIterator", "P<K, A>", "next", true)»
		}

		final class SortedDictView<K, A> extends BaseSortedKeyValueView<K, A, SortedDict<K, A>> {
			static final SortedDictView<?, ?> EMPTY = new SortedDictView<>(SortedDict.EMPTY);
			static final SortedDictView<?, ?> EMPTY_REVERSED = new SortedDictView<>(SortedDict.EMPTY_REVERSED);

			SortedDictView(final SortedDict<K, A> keyValue) {
				super(keyValue);
			}

			@Override
			public SortedKeyValueView<K, A> slice(final K from, final boolean fromInclusive, final K to, final boolean toInclusive) {
				checkRange(this.keyValue.ord, from, to);
				return new SlicedSortedDictView<>(this.keyValue, from, true, fromInclusive, to, true, toInclusive);
			}

			@Override
			public SortedKeyValueView<K, A> sliceFrom(final K from, final boolean inclusive) {
				return new SlicedSortedDictView<>(this.keyValue, from, true, inclusive, null, false, false);
			}

			@Override
			public SortedKeyValueView<K, A> sliceTo(final K to, final boolean inclusive) {
				return new SlicedSortedDictView<>(this.keyValue, null, false, false, to, true, inclusive);
			}
		}

		final class SlicedSortedDictView<K, A> implements SortedKeyValueView<K, A> {

			private final «genericName» root;
			private final K from;
			private final boolean hasFrom;
			private final boolean fromInclusive;
			private final K to;
			private final boolean hasTo;
			private final boolean toInclusive;

			SlicedSortedDictView(final «genericName» root,
				final K from, final boolean hasFrom, final boolean fromInclusive,
				final K to, final boolean hasTo, final boolean toInclusive) {
				this.root = root;
				this.from = from;
				this.hasFrom = hasFrom;
				this.fromInclusive = fromInclusive;
				this.to = to;
				this.hasTo = hasTo;
				this.toInclusive = toInclusive;
			}

			@Override
			public int size() {
				return iterableSize(this);
			}

			@Override
			public boolean hasKnownFixedSize() {
				return false;
			}

			@Override
			public Ord<K> ord() {
				return this.root.ord;
			}

			«AVLCommonGenerator.slicedForEach("forEach", genericName, "dict", "entry.get1()", "Consumer<? super P<K, A>>", "accept")»

			@Override
			public A getOrNull(final K key) {
				«AVLCommonGenerator.slicedSearch(Type.OBJECT, "key", "null", shortName)»
			}

			@Override
			public SortedKeyValueView<K, A> slice(final K from2, final boolean from2Inclusive, final K to2, final boolean to2Inclusive) {
				checkRange(this.root.ord, from2, to2);
				return slice(from2, true, from2Inclusive, to2, true, to2Inclusive);
			}

			@Override
			public SortedKeyValueView<K, A> sliceFrom(final K from2, final boolean inclusive2) {
				return slice(from2, true, inclusive2, null, false, false);
			}

			@Override
			public SortedKeyValueView<K, A> sliceTo(final K to2, final boolean inclusive2) {
				return slice(null, false, false, to2, true, inclusive2);
			}

			private SortedKeyValueView<K, A> slice(final K from2, final boolean hasFrom2, final boolean from2Inclusive,
				final K to2, final boolean hasTo2, final boolean to2Inclusive) {
				«AVLCommonGenerator.slicedSlice("K", "SortedDictView<>", "SlicedSortedDictView<>", "SortedDict")»
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				if (this.root.isEmpty()) {
					return emptyIterator();
				} else {
					return new SlicedSortedDictIterator<>(this.root, this.from, this.hasFrom, this.fromInclusive, this.to, this.hasTo, this.toInclusive);
				}
			}

			@Override
			public Iterator<P<K, A>> reverseIterator() {
				if (this.root.isEmpty()) {
					return emptyIterator();
				} else {
					return new SlicedSortedDictReverseIterator<>(this.root, this.from, this.hasFrom, this.fromInclusive, this.to, this.hasTo, this.toInclusive);
				}
			}

			«keyValueEquals»

			«keyValueHashCode»

			«keyValueToString»
		}

		final class SlicedSortedDictIterator<K, A> implements Iterator<P<K, A>> {
			«AVLCommonGenerator.slicedIterator(genericName, "dict", "SlicedSortedDictIterator", "K", "entry.get1()", "<K, A> ", "Ord<K>", "P<K, A>", "next", false)»
		}

		final class SlicedSortedDictReverseIterator<K, A> implements Iterator<P<K, A>> {
			«AVLCommonGenerator.slicedIterator(genericName, "dict", "SlicedSortedDictReverseIterator", "K", "entry.get1()", "<K, A> ", "Ord<K>", "P<K, A>", "next", true)»
		}
	''' }
}