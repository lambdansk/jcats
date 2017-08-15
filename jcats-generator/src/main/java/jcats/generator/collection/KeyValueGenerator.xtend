package jcats.generator.collection

import jcats.generator.Constants
import jcats.generator.InterfaceGenerator
import jcats.generator.Type

final class KeyValueGenerator implements InterfaceGenerator {

	override className() { Constants.COLLECTION + ".KeyValue" }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.ArrayList;
		import java.util.Collection;
		import java.util.Iterator;
		import java.util.HashSet;
		import java.util.Map;
		import java.util.Map.Entry;
		import java.util.Set;
		import java.util.Spliterator;
		import java.util.Spliterators;
		import java.util.function.BiConsumer;
		import java.util.function.Consumer;
		import java.util.stream.StreamSupport;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.COMMON».*;
		import static «Constants.EITHER».*;

		public interface KeyValue<K, A> extends Iterable<P<K, A>>, Equatable<KeyValue<K, A>>, Sized {

			default Option<A> get(final K key) {
				return Option.fromNullable(getOrNull(key));
			}

			default A getOr(final K key, final A other) {
				requireNonNull(other);
				final A value = getOrNull(key);
				return (value == null) ? other : value;
			}

			default A getOrElse(final K key, final F0<A> other) {
				requireNonNull(other);
				final A value = getOrNull(key);
				return (value == null) ? requireNonNull(other.apply()) : value;
			}

			default <X> Either<X, A> getOrError(final K key, final F0<X> error) {
				requireNonNull(error);
				final A value = getOrNull(key);
				return (value == null) ? left(requireNonNull(error.apply())) : right(value);
			}

			default <X extends Throwable> A getOrThrow(final K key, final F0<X> f) throws X {
				requireNonNull(f);
				final A value = getOrNull(key);
				if (value == null) {
					throw f.apply();
				} else {
					return value;
				}
			}

			A getOrNull(final K key);

			default boolean containsKey(final K key) {
				return (getOrNull(key) != null);
			}

			default boolean containsValue(final A value) {
				requireNonNull(value);
				for (final P<K, A> entry : this) {
					if (entry.get2().equals(value)) {
						return true;
					}
				}
				return false;
			}

			default void foreach(final Eff2<K, A> eff) {
				requireNonNull(eff);
				forEach((final P<K, A> entry) -> eff.apply(entry.get1(), entry.get2()));
			}

			default UniqueContainer<K> keys() {
				return new Keys<>(this);
			}

			default Container<A> values() {
				return new Values<>(this);
			}

			default Map<K, A> asMap() {
				return new KeyValueAsMap<>(this);
			}

			@Override
			default Spliterator<P<K, A>> spliterator() {
				if (isEmpty()) {
					return Spliterators.emptySpliterator();
				} else {
					return Spliterators.spliterator(iterator(), size(), Spliterator.NONNULL | Spliterator.DISTINCT | Spliterator.IMMUTABLE);
				}
			}

			default Stream2<P<K, A>> stream() {
				return new Stream2<>(StreamSupport.stream(spliterator(), false));
			}

			default Stream2<P<K, A>> parallelStream() {
				return new Stream2<>(StreamSupport.stream(spliterator(), true));
			}

			default ArrayList<P<K, A>> toArrayList() {
				final ArrayList<P<K, A>> list = new ArrayList<>(size());
				forEach(list::add);
				return list;
			}

			default HashSet<P<K, A>> toHashSet() {
				final HashSet<P<K, A>> list = new HashSet<>(Math.max((int) (size() / 0.75f) + 1, 16));
				forEach(list::add);
				return list;
			}

			default Array<P<K, A>> toArray() {
				return Array.sizedToArray(this, size());
			}

			default Seq<P<K, A>> toSeq() {
				return Seq.sizedToSeq(iterator(), size());
			}

			«cast(#["K", "A"], #[], #["A"])»
		}

		final class Values<A> implements Container<A> {
			private final KeyValue<?, A> keyValue;

			Values(final KeyValue<?, A> keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return keyValue.size();
			}

			@Override
			public boolean contains(final A value) {
				return keyValue.containsValue(value);
			}

			@Override
			public void foreach(final Eff<A> eff) {
				keyValue.forEach((final P<?, A> p) -> eff.apply(p.get2()));
			}

			@Override
			public void forEach(final Consumer<? super A> consumer) {
				keyValue.forEach((final P<?, A> p) -> consumer.accept(p.get2()));
			}

			@Override
			public Iterator<A> iterator() {
				return new MappedIterator<>(keyValue.iterator(), P::get2);
			}

			@Override
			public Spliterator<A> spliterator() {
				if (isEmpty()) {
					return Spliterators.emptySpliterator();
				} else {
					return Spliterators.spliterator(iterator(), size(), Spliterator.NONNULL | Spliterator.IMMUTABLE);
				}
			}

			@Override
			public String toString() {
				return iterableToString(this, "Values");
			}
		}

		final class Keys<K> implements UniqueContainer<K> {
			private final KeyValue<K, ?> keyValue;

			Keys(final KeyValue<K, ?> keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return keyValue.size();
			}

			@Override
			public boolean contains(final K key) {
				return keyValue.containsKey(key);
			}

			@Override
			public void foreach(final Eff<K> eff) {
				keyValue.forEach((final P<K, ?> p) -> eff.apply(p.get1()));
			}

			@Override
			public void forEach(final Consumer<? super K> consumer) {
				keyValue.forEach((final P<K, ?> p) -> consumer.accept(p.get1()));
			}

			@Override
			public Iterator<K> iterator() {
				return new MappedIterator<>(keyValue.iterator(), P::get1);
			}

			«uniqueHashCode»

			«uniqueEquals(Type.OBJECT, "UniqueContainer")»

			@Override
			public String toString() {
				return iterableToString(this, "Keys");
			}
		}

		final class KeyValueAsMap<K, A> extends AbstractImmutableMap<K, A> {
			private final KeyValue<K, A> keyValue;

			KeyValueAsMap(final KeyValue<K, A> keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return keyValue.size();
			}

			@Override
			public boolean isEmpty() {
				return keyValue.isEmpty();
			}

			@Override
			public boolean containsKey(final Object key) {
				return (key != null) && keyValue.containsKey((K) key);
			}

			@Override
			public boolean containsValue(final Object value) {
				return (value != null) && keyValue.containsValue((A) value);
			}

			@Override
			public A get(final Object key) {
				if (key == null) {
					return null;
				} else {
					return keyValue.getOrNull((K) key);
				}
			}

			@Override
			public A getOrDefault(final Object key, final A defaultValue) {
				if (key == null) {
					return defaultValue;
				} else {
					final A value = keyValue.getOrNull((K) key);
					return (value == null) ? defaultValue : value;
				}
			}

			@Override
			public Set<Entry<K, A>> entrySet() {
				return new KeyValueEntrySet<>(keyValue);
			}

			@Override
			public Set<K> keySet() {
				return keyValue.keys().asSet();
			}

			@Override
			public Collection<A> values() {
				return keyValue.values().asCollection();
			}

			@Override
			public void forEach(final BiConsumer<? super K, ? super A> action) {
				keyValue.forEach((final P<K, A> entry) -> action.accept(entry.get1(), entry.get2()));
			}
		}

		final class KeyValueEntrySet<K, A> extends AbstractImmutableSet<Entry<K, A>> {
			private final KeyValue<K, A> keyValue;

			KeyValueEntrySet(final KeyValue<K, A> keyValue) {
				this.keyValue = keyValue;
			}

			@Override
			public int size() {
				return keyValue.size();
			}

			@Override
			public boolean contains(final Object obj) {
				if (obj instanceof Entry) {
					final Entry<?, ?> entry = (Entry<?, ?>) obj;
					final Object key = entry.getKey();
					if (key == null) {
						return false;
					} else {
						final Object value = entry.getValue();
						return (value != null) && value.equals(keyValue.getOrNull((K) key));
					}
				} else {
					return false;
				}
			}

			@Override
			public Iterator<Entry<K, A>> iterator() {
				return new MappedIterator<>(keyValue.iterator(), P::toEntry);
			}

			@Override
			public Spliterator<Entry<K, A>> spliterator() {
				if (isEmpty()) {
					return Spliterators.emptySpliterator();
				} else {
					return Spliterators.spliterator(this, Spliterator.NONNULL | Spliterator.DISTINCT | Spliterator.IMMUTABLE);
				}
			}

			@Override
			public void forEach(final Consumer<? super Entry<K, A>> action) {
				keyValue.forEach((final P<K, A> p) -> action.accept(p.toEntry()));
			}
		}
	''' }

}