package jcats.generator.collection

import java.util.List
import jcats.generator.Constants
import jcats.generator.Generator
import jcats.generator.InterfaceGenerator
import jcats.generator.Type
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
final class UniqueContainerViewGenerator implements InterfaceGenerator {
	val Type type

	def static List<Generator> generators() {
		Type.values.filter[it != Type.BOOLEAN].toList.map[new UniqueContainerViewGenerator(it) as Generator]
	}

	override className() { Constants.COLLECTION + "." + shortName }

	def shortName() { type.shortName("UniqueContainerView") }
	def genericName() { type.genericName("UniqueContainerView") }
	def baseUniqueContainerViewShortName() { type.shortName("BaseUniqueContainerView") }

	override sourceCode() { '''
		package «Constants.COLLECTION»;

		import java.util.Set;

		import «Constants.JCATS».*;

		«IF type == Type.OBJECT»
			import static java.util.Objects.requireNonNull;
		«ENDIF»
		import static «Constants.COMMON».*;

		public interface «type.covariantName("UniqueContainerView")» extends «type.containerViewGenericName», «type.uniqueContainerGenericName» {

			@Override
			@Deprecated
			default «type.uniqueContainerViewGenericName» view() {
				return this;
			}
			«IF type == Type.OBJECT»

				«cast(#["A"], #[], #["A"])»
			«ENDIF»
		}

		«IF type == Type.OBJECT»
			final class «baseUniqueContainerViewShortName»<A, C extends UniqueContainer<A>> extends BaseContainerView<A, C> implements UniqueContainerView<A> {
		«ELSE»
			final class «baseUniqueContainerViewShortName»<C extends «type.uniqueContainerShortName»> extends «type.typeName»BaseContainerView<C> implements «type.uniqueContainerViewShortName» {
		«ENDIF»

			«baseUniqueContainerViewShortName»(final C container) {
				super(container);
			}

			@Override
			public Set<«type.genericBoxedName»> asCollection() {
				return this.container.asCollection();
			}

			«IF type.primitive»
				@Override
				public UniqueContainer<«type.boxedName»> asContainer() {
					return this.container.asContainer();
				}

			«ENDIF»
			«uniqueHashCode(type)»

			«uniqueEquals(type)»

			@Override
			public String toString() {
				return iterableToString(this, "«baseUniqueContainerViewShortName»");
			}
		}
	''' }
}