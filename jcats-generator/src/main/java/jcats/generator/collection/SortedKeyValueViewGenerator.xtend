package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator

final class SortedKeyValueViewGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".SortedKeyValueView" }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.Collections;
		import java.util.Comparator;
		import java.util.Iterator;
		import java.util.NavigableMap;
		import java.util.SortedMap;
		import java.util.TreeMap;

		import «Constants.JCATS».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.ORD».*;
		import static «Constants.P».*;
		import static «Constants.COMMON».*;

		public interface SortedKeyValueView<K, @Covariant A> extends KeyValueView<K, A>, SortedKeyValue<K, A> {

			SortedKeyValueView<K, A> slice(K from, boolean fromInclusive, K to, boolean toInclusive);

			SortedKeyValueView<K, A> sliceFrom(K from, boolean inclusive);

			SortedKeyValueView<K, A> sliceTo(K to, boolean inclusive);

			@Override
			@Deprecated
			default SortedKeyValueView<K, A> view() {
				return this;
			}

			default SortedKeyValueView<K, A> reverse() {
				return new ReverseSortedKeyValueView<>(this);
			}

			static <K, A> SortedKeyValueView<K, A> sortedMapView(final SortedMap<K, A> map) {
				return sortedMapView(map, true);
			}

			static <K, A> SortedKeyValueView<K, A> sortedMapView(final SortedMap<K, A> map, final boolean hasKnownFixedSize) {
				requireNonNull(map);
				return new SortedMapAsSortedKeyValue<>(map, hasKnownFixedSize);
			}

			«cast(#["K", "A"], #[], #["A"])»
		}

		abstract class BaseSortedKeyValueView<K, A, KV extends SortedKeyValue<K, A>> extends BaseKeyValueView<K, A, KV> implements SortedKeyValueView<K, A> {

			BaseSortedKeyValueView(final KV keyValue) {
				super(keyValue);
			}

			@Override
			public Ord<K> ord() {
				return this.keyValue.ord();
			}

			@Override
			public P<K, A> first() {
				return this.keyValue.first();
			}

			@Override
			public P<K, A> last() {
				return this.keyValue.last();
			}

			@Override
			public K firstKey() {
				return this.keyValue.firstKey();
			}

			@Override
			public K lastKey() {
				return this.keyValue.lastKey();
			}

			@Override
			public SortedUniqueContainerView<K> keys() {
				return this.keyValue.keys();
			}

			@Override
			public OrderedContainerView<A> values() {
				return this.keyValue.values();
			}

			@Override
			public SortedUniqueContainerView<P<K, A>> asUniqueContainer() {
				return this.keyValue.asUniqueContainer();
			}

			@Override
			public TreeMap<K, A> toTreeMap() {
				return this.keyValue.toTreeMap();
			}

			@Override
			public SortedMap<K, A> asMap() {
				return this.keyValue.asMap();
			}
		}

		final class ReverseSortedKeyValueView<K, A> implements SortedKeyValueView<K, A> {
			final SortedKeyValueView<K, A> view;

			ReverseSortedKeyValueView(final SortedKeyValueView<K, A> view) {
				this.view = view;
			}

			@Override
			public int size() {
				return this.view.size();
			}

			@Override
			public boolean isEmpty() {
				return this.view.isEmpty();
			}

			@Override
			public boolean isNotEmpty() {
				return this.view.isNotEmpty();
			}

			@Override
			public boolean hasKnownFixedSize() {
				return this.view.hasKnownFixedSize();
			}

			@Override
			public A getOrNull(final K key) {
				return this.view.getOrNull(key);
			}

			@Override
			public Ord<K> ord() {
				return this.view.ord().reversed();
			}

			@Override
			public P<K, A> first() {
				return this.view.last();
			}

			@Override
			public P<K, A> last() {
				return this.view.first();
			}

			@Override
			public K firstKey() {
				return this.view.lastKey();
			}

			@Override
			public K lastKey() {
				return this.view.firstKey();
			}

			@Override
			public SortedUniqueContainerView<K> keys() {
				return this.view.keys().reverse();
			}

			@Override
			public OrderedContainerView<A> values() {
				return this.view.values().reverse();
			}

			@Override
			public SortedUniqueContainerView<P<K, A>> asUniqueContainer() {
				return this.view.asUniqueContainer().reverse();
			}

			@Override
			public SortedKeyValueView<K, A> slice(final K from, final boolean fromInclusive, final K to, final boolean toInclusive) {
				return new ReverseSortedKeyValueView<>(this.view.slice(to, toInclusive, from, fromInclusive));
			}

			@Override
			public SortedKeyValueView<K, A> sliceFrom(final K from, final boolean inclusive) {
				return new ReverseSortedKeyValueView<>(this.view.sliceTo(from, inclusive));
			}

			@Override
			public SortedKeyValueView<K, A> sliceTo(final K to, final boolean inclusive) {
				return new ReverseSortedKeyValueView<>(this.view.sliceFrom(to, inclusive));
			}

			@Override
			public Iterator<P<K, A>> iterator() {
				return this.view.reverseIterator();
			}

			@Override
			public Iterator<P<K, A>> reverseIterator() {
				return this.view.iterator();
			}

			@Override
			public int hashCode() {
				return this.view.hashCode();
			}

			@Override
			public boolean equals(final Object obj) {
				return this.view.equals(obj);
			}

			@Override
			public String toString() {
				return iterableToString(this);
			}
		}

		final class SortedMapAsSortedKeyValue<K, A> extends MapAsKeyValue<K, A, SortedMap<K, A>> implements SortedKeyValueView<K, A> {

			SortedMapAsSortedKeyValue(final SortedMap<K, A> map, final boolean fixedSize) {
				super(map, fixedSize);
			}

			@Override
			public Ord<K> ord() {
				final Comparator<K> comparator = (Comparator<K>) this.map.comparator();
				if (comparator == null) {
					return (Ord<K>) asc();
				} else {
					return Ord.fromComparator(comparator);
				}
			}

			@Override
			public P<K, A> first() {
				final K key = this.map.firstKey();
				final A value = this.map.get(key);
				return p(key, value);
			}

			@Override
			public P<K, A> last() {
				final K key = this.map.lastKey();
				final A value = this.map.get(key);
				return p(key, value);
			}

			@Override
			public K firstKey() {
				return this.map.firstKey();
			}

			@Override
			public K lastKey() {
				return this.map.lastKey();
			}

			@Override
			public SortedKeyValueView<K, A> slice(final K from, final boolean fromInclusive, final K to, final boolean toInclusive) {
				requireNonNull(from);
				requireNonNull(to);
				final SortedMap<K, A> subMap;
				if (fromInclusive && !toInclusive) {
					subMap = this.map.subMap(from, to);
				} else {
					subMap = ((NavigableMap<K, A>) this.map).subMap(from, fromInclusive, to, toInclusive);
				}
				return new SortedMapAsSortedKeyValue<>(subMap, hasKnownFixedSize());
			}

			@Override
			public SortedKeyValueView<K, A> sliceFrom(final K from, final boolean inclusive) {
				requireNonNull(from);
				final SortedMap<K, A> tailMap;
				if (inclusive) {
					tailMap = this.map.tailMap(from);
				} else {
					tailMap = ((NavigableMap<K, A>) this.map).tailMap(from, inclusive);
				}
				return new SortedMapAsSortedKeyValue<>(tailMap, hasKnownFixedSize());
			}

			@Override
			public SortedKeyValueView<K, A> sliceTo(final K to, final boolean inclusive) {
				requireNonNull(to);
				final SortedMap<K, A> headMap;
				if (inclusive) {
					headMap = ((NavigableMap<K, A>) this.map).headMap(to, inclusive);
				} else {
					headMap = this.map.headMap(to);
				}
				return new SortedMapAsSortedKeyValue<>(headMap, hasKnownFixedSize());
			}

			@Override
			public SortedMap<K, A> asMap() {
				return Collections.unmodifiableSortedMap(this.map);
			}
		}
	'''
}