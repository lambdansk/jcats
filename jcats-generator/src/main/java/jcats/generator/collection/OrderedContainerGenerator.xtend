package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class OrderedContainerGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.toList.map[new OrderedContainerGenerator(it) as Generator].toList
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.orderedContainerShortName }
	def genericName() { type.orderedContainerGenericName }

	override sourceCode() '''
		package «Constants.COLLECTION»;

		import java.util.NoSuchElementException;
		import java.util.Iterator;
		«IF type.javaUnboxedType»
			import java.util.PrimitiveIterator;
		«ENDIF»
		import java.util.Spliterator;

		import «Constants.JCATS».*;
		import «Constants.FUNCTION».*;

		import static java.util.Objects.requireNonNull;
		import static «Constants.JCATS».«type.optionShortName».*;
		import static «Constants.COLLECTION».«type.orderedContainerViewShortName».*;

		public interface «type.covariantName("OrderedContainer")» extends «type.containerGenericName» {

			default «type.genericName» last() throws NoSuchElementException {
				if (isReverseQuick()) {
					return reverseIterator().«type.iteratorNext»();
				} else {
					final «type.iteratorGenericName» iterator = iterator();
					«type.genericName» result = iterator.«type.iteratorNext»();
					while (true) {
						if (!iterator.hasNext()) {
							return result;
						}
						result = iterator.«type.iteratorNext»();
					}
				}
			}

			default «type.optionGenericName» findLast() {
				if (hasKnownFixedSize() && isEmpty()) {
					return «type.noneName»();
				} else if (isReverseQuick()) {
					return «type.someName»(last());
				} else {
					final «type.iteratorGenericName» iterator = iterator();
					if (iterator.hasNext()) {
						«type.genericName» result = iterator.«type.iteratorNext»();
						while (iterator.hasNext()) {
							result = iterator.«type.iteratorNext»();
						}
						return «type.someName»(result);
					} else {
						return «type.noneName»();
					}
				}
			}

			default «type.optionGenericName» lastMatch(final «type.boolFName» predicate) {
				requireNonNull(predicate);
				if (isReverseQuick()) {
					final «type.iteratorGenericName» iterator = reverseIterator();
					while (iterator.hasNext()) {
						final «type.genericName» value = iterator.«type.iteratorNext»();
						if (predicate.apply(value)) {
							return «type.someName»(value);
						}
					}
					return «type.noneName»();
				} else {
					final «type.javaName»[] result = { «type.defaultValue» };
					final boolean[] found = { false };
					foreach(value -> {
						if (predicate.apply(value)) {
							result[0] = value;
							found[0] = true;
						}
					});
					if (found[0]) {
						return «type.someName»(«type.genericCast»result[0]);
					} else {
						return «type.noneName»();
					}
				}
			}

			«IF type.primitive»
				default <A> A foldRight(final A start, final «type.typeName»ObjectObjectF2<A, A> f2) {
			«ELSE»
				default <B> B foldRight(final B start, final F2<A, B, B> f2) {
			«ENDIF»
				requireNonNull(start);
				requireNonNull(f2);
				«IF type == Type.OBJECT»B«ELSE»A«ENDIF» result = start;
				final «type.iteratorGenericName» iterator = reverseIterator();
				while (iterator.hasNext()) {
					final «type.genericName» value = iterator.«type.iteratorNext»();
					result = requireNonNull(f2.apply(value, result));
				}
				return result;
			}

			«FOR returnType : Type.primitives»
				«IF type == Type.OBJECT»
					default «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final Object«returnType.typeName»«returnType.typeName»F2<A> f2) {
				«ELSE»
					default «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final «type.typeName»«returnType.typeName»«returnType.typeName»F2 f2) {
				«ENDIF»
					requireNonNull(f2);
					«returnType.javaName» result = start;
					final «type.iteratorGenericName» iterator = reverseIterator();
					while (iterator.hasNext()) {
						final «type.genericName» value = iterator.«type.iteratorNext»();
						result = f2.apply(value, result);
					}
					return result;
				}

			«ENDFOR»
			default «type.iteratorGenericName» reverseIterator() {
				return to«type.arrayShortName»().reverseIterator();
			}

			default boolean isReverseQuick() {
				return false;
			}

			@Override
			default int spliteratorCharacteristics() {
				return Spliterator.NONNULL | Spliterator.ORDERED | Spliterator.IMMUTABLE;
			}

			@Override
			default «type.orderedContainerViewGenericName» view() {
				if (hasKnownFixedSize() && isEmpty()) {
					return empty«type.orderedContainerViewShortName»();
				} else {
					return new «type.shortName("BaseOrderedContainerView")»<>(this);
				}
			}

			«IF type.primitive»
				@Override
				default OrderedContainerView<«type.boxedName»> boxed() {
					return new «type.typeName»BoxedOrderedContainer<>(this);
				}

			«ENDIF»
			static «type.paramGenericName("OrderedContainerView")» generate(final «type.f0GenericName» f) {
				requireNonNull(f);
				return new «type.diamondName("GeneratedOrderedContainerView")»(f);
			}

			static «type.paramGenericName("OrderedContainerView")» iterate(final «type.genericName» start, final «type.endoGenericName» f) {
				«IF type == Type.OBJECT»
					requireNonNull(start);
				«ENDIF»
				requireNonNull(f);
				return new «type.diamondName("IteratingOrderedContainerView")»(start, f);
			}

			static «type.paramGenericName("OrderedContainerView")» iterateWhile(final «type.genericName» start, final «type.boolFName» hasNext, final «type.endoGenericName» next) {
				«IF type == Type.OBJECT»
					requireNonNull(start);
				«ENDIF»
				requireNonNull(hasNext);
				requireNonNull(next);
				return new «type.diamondName("IteratingWhileOrderedContainerView")»(start, hasNext, next);
			}

			«IF type == Type.OBJECT»
				@SafeVarargs
			«ENDIF»
			static «type.paramGenericName("OrderedContainerView")» concat(final «genericName»... containers) {
				if (containers.length == 0) {
					return empty«type.orderedContainerViewShortName»();
				} else if (containers.length == 1) {
					return requireNonNull(containers[0].view());
				} else {
					for (final «genericName» container : containers) {
						requireNonNull(container);
					}
					return new «type.shortName("ConcatenatedOrderedContainerView")»<>(containers);
				}
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}
		«IF type.primitive»

			class «type.typeName»BoxedOrderedContainer<C extends «shortName»> extends «type.typeName»BoxedContainer<C> implements OrderedContainerView<«type.boxedName»> {

				«type.typeName»BoxedOrderedContainer(final C container) {
					super(container);
				}

				@Override
				public «type.boxedName» last() {
					return this.container.last();
				}

				@Override
				public Option<«type.boxedName»> findLast() {
					return this.container.findLast().toOption();
				}

				@Override
				public Option<«type.boxedName»> lastMatch(final BooleanF<«type.boxedName»> predicate) {
					return this.container.lastMatch(predicate::apply).toOption();
				}

				@Override
				public <A> A foldRight(final A start, final F2<«type.boxedName», A, A> f2) {
					return this.container.foldRight(start, f2::apply);
				}

				«FOR returnType : Type.primitives»
					@Override
					public «returnType.javaName» foldRightTo«returnType.typeName»(final «returnType.javaName» start, final Object«returnType.typeName»«returnType.typeName»F2<«type.boxedName»> f2) {
						return this.container.foldRightTo«returnType.typeName»(start, f2::apply);
					}

				«ENDFOR»
				@Override
				public Iterator<«type.genericBoxedName»> reverseIterator() {
					return this.container.reverseIterator();
				}

				@Override
				public boolean isReverseQuick() {
					return this.container.isReverseQuick();
				}
			}
		«ENDIF»
	'''
}