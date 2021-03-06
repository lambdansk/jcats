package jcats.generator

import com.google.common.collect.Sets

import static extension com.google.common.collect.Iterables.contains
import static extension java.lang.Character.toLowerCase

interface Generator {
	def String className()
	def String name() { className.substring(className.lastIndexOf('.') + 1) }

	val public static PRIMITIVES = #["int", "long", "boolean", "double", "float", "short", "byte"]

	def String sourceCode()

	def ea() { false }

	def toStr() { toStr(Type.OBJECT) }

	def toStr(Type type) { toStr(type, "this") }

	def toStr(Type type, String obj) { '''
		@Override
		public String toString() {
			«IF type.javaUnboxedType»
				return «type.containerShortName.firstToLowerCase»ToString(«obj»);
			«ELSE»
				return iterableToString(«obj»);
			«ENDIF»
		}
	'''}

	def static keyValueToString() { keyValueToString("this") }

	def static keyValueToString(String obj) '''
		@Override
		public String toString() {
			return keyValueToString(«obj»);
		}
	'''

	def static orderedHashCode(Type type) { orderedHashCode(type, false) }

	def static orderedHashCode(Type type, boolean isFinal) '''
		@Override
		public «IF isFinal»final «ENDIF»int hashCode() {
			«IF type.primitive»
				return «type.orderedContainerShortName.firstToLowerCase»HashCode(this);
			«ELSE»
				return orderedContainerHashCode(this);
			«ENDIF»
		}
	'''

	def static uniqueHashCode(Type type) { '''
		@Override
		public int hashCode() {
			«IF type.primitive»
				return «type.uniqueContainerShortName.firstToLowerCase»HashCode(this);
			«ELSE»
				return uniqueContainerHashCode(this);
			«ENDIF»
		}
	'''}

	def static keyValueHashCode() { '''
		@Override
		public int hashCode() {
			return asUniqueContainer().hashCode();
		}
	'''}

	def static equals(Type type, String wildcardName, boolean isFinal) {'''
		/**
		 * «equalsDeprecatedJavaDoc»
		 */
		@Override
		@Deprecated
		public «IF isFinal»final «ENDIF»boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof «wildcardName») {
				return «type.indexedContainerShortName.firstToLowerCase»sEqual(this, («wildcardName») obj);
			} else {
				return false;
			}
		}
	'''}

	def static indexedEquals(Type type) { equals(type, type.indexedContainerWildcardName, false) }

	def static uniqueEquals(Type type) {'''
		/**
		 * «equalsDeprecatedJavaDoc»
		 */
		@Override
		@Deprecated
		public boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof «type.uniqueContainerWildcardName») {
				return «type.uniqueContainerShortName.firstToLowerCase»sEqual(this, («type.uniqueContainerWildcardName») obj);
			} else {
				return false;
			}
		}
	'''}

	def static keyValueEquals() {'''
		/**
		 * «equalsDeprecatedJavaDoc»
		 */
		@Override
		@Deprecated
		public boolean equals(final Object obj) {
			if (obj == this) {
				return true;
			} else if (obj instanceof KeyValue<?, ?>) {
				return keyValuesEqual((KeyValue<Object, ?>) this, (KeyValue<Object, ?>) obj);
			} else {
				return false;
			}
		}
	'''}

	def static equalsDeprecatedJavaDoc() { "@deprecated This method is not type-safe. Use {@link #isEqualTo} instead." }

	def static repeat(Type type, String paramGenericName) { '''
		public static «paramGenericName» repeat(final int size, final «type.genericName» value) {
			return tabulate(size, int«type.typeName»Always(value));
		}
	'''}

	def static fill(Type type, String paramGenericName) { '''
		public static «paramGenericName» fill(final int size, final «IF type == Type.OBJECT»F0<A>«ELSE»«type.typeName»F0«ENDIF» f) {
			return tabulate(size, f.toInt«type.typeName»F());
		}
	'''}

	def static fillUntil(Type type, String paramGenericName, String builderName, String method) { '''
		public static «paramGenericName» fillUntil(final F0<«type.optionGenericName»> f) {
			final «builderName» builder = builder();
			«type.optionGenericName» value = f.apply();
			while (value.isNotEmpty()) {
				builder.«method»(value.get());
				value = f.apply();
			}
			return builder.build();
		}
	''' }

	def static iterateWhile(Type type, String paramGenericName, String builderName) { '''
		public static «paramGenericName» iterateWhile(final «type.genericName» start, final «type.boolFName» hasNext, final «type.endoGenericName» next) {
			requireNonNull(next);
			final «builderName» builder = builder();
			«type.genericName» value = start;
			while (hasNext.apply(value)) {
				builder.append(value);
				value = «type.requireNonNull("next.apply(value)")»;
			}
			return builder.build();
		}
	''' }

	def static iterateUntil(Type type, String paramGenericName, String builderName) { '''
		«IF type == Type.OBJECT»
			public static «paramGenericName» iterateUntil(final A start, final F<A, Option<A>> f) {
		«ELSE»
			public static «paramGenericName» iterateUntil(final «type.javaName» start, final «type.typeName»ObjectF<«type.optionShortName»> f) {
		«ENDIF»
			final «builderName» builder = builder();
			builder.append(start);
			«type.optionGenericName» option = f.apply(start);
			while (option.isNotEmpty()) {
				final «type.genericName» value = option.get();
				builder.append(value);
				option = f.apply(value);
			}
			return builder.build();
		}
	''' }

	def flattenCollection(Type type, String genericName, String builderGenericName) '''
		public static <«IF type == Type.OBJECT»A, «ENDIF»C extends Iterable<«type.genericBoxedName»>> «genericName» flatten(final Iterable<C> iterable) {
			final «builderGenericName» builder = builder();
			if (iterable instanceof Container<?>) {
				((Container<C>) iterable).foreach(builder::appendAll);
			} else {
				iterable.forEach(builder::appendAll);
			}
			return builder.build();
		}
	'''

	def flatten() { flatten(#[], "A") }

	def flatten(Iterable<String> typeParams, String typeParam) '''
		«staticModifier» <«typeParams.map[it + ", "].join»«typeParam»> «name»<«typeParams.map[it + ", "].join»«typeParam»> flatten(final «name»<«typeParams.map[it + ", "].join»«name»<«typeParams.map[it + ", "].join»«typeParam»>> «name.firstToLowerCase») {
			return «name.firstToLowerCase».flatMap(id());
		}
	'''

	def static firstToLowerCase(String str) {
		if (str.empty) {
			str
		} else {
			str.toCharArray.head.toLowerCase + str.toCharArray.tail.join
		}
	}

	def static streamForEach(String elementType, String method, boolean ordered) { '''
		if (stream.isParallel()) {
			stream.forEach«IF ordered»Ordered«ENDIF»((final «elementType» value) -> {
				synchronized (this) {
					«method»(value);
				}
			});
		} else {
			stream.forEach«IF ordered»Ordered«ENDIF»(this::«method»);
		}
	''' }

	def cast(Iterable<String> typeParams, Iterable<String> contravariantTypeParams, Iterable<String> covariantTypeParams) {
		cast(name, "cast", typeParams, contravariantTypeParams, covariantTypeParams)
	}

	def cast(String typeName, String methodName, Iterable<String> typeParams, Iterable<String> contravariantTypeParams, Iterable<String> covariantTypeParams) {
		val argumentType = '''«typeName»<«typeParams.join(", ")»>'''
		val returnType = '''«typeName»<«typeParams.map[
			if (contravariantTypeParams.contains(it) || covariantTypeParams.contains(it)) it + "X" else it].join(", ")»>'''

		val invariantTypeParams = Sets.newHashSet(typeParams)
		invariantTypeParams.removeAll(contravariantTypeParams)
		invariantTypeParams.removeAll(covariantTypeParams)

		val methodParams = new StringBuilder
		if (!contravariantTypeParams.empty) {
			methodParams.append(contravariantTypeParams.join(", "))
			methodParams.append(", ")
			methodParams.append(contravariantTypeParams.map[it + "X extends " + it].join(", "))
			if (!covariantTypeParams.empty || !invariantTypeParams.empty) {
				methodParams.append(", ")
			}
		}
		if (!covariantTypeParams.empty) {
			methodParams.append(covariantTypeParams.map[it + "X"].join(", "))
			methodParams.append(", ")
			methodParams.append(covariantTypeParams.map[it + " extends " + it + "X"].join(", "))
			if (!invariantTypeParams.empty) {
				methodParams.append(", ")
			}
		}
		if (!invariantTypeParams.empty) {
			methodParams.append(invariantTypeParams.join(", "))
		}

		'''
		«staticModifier» <«methodParams»> «returnType» «methodName»(final «argumentType» «typeName.firstToLowerCase») {
			return («returnType») requireNonNull(«typeName.firstToLowerCase»);
		}
		'''
	}

	def staticModifier() {
		if (this instanceof InterfaceGenerator) "static" else "public static"
	}

	def javadocSynonym(String of) {
		return '''
			/**
			 * Alias for {@link #«of»}
			 */
		'''
	}

	def indexOutOfBounds() '''throw new IndexOutOfBoundsException(getIndexOutOfBoundsMessage(index, this));'''

	def transform(String genericName) { transform(genericName, false) }

	def transform(String genericName, boolean isFinal) '''
		public «IF isFinal»final «ENDIF»<R> R transform(final F<«genericName», R> f) {
			return requireNonNull(f.apply(this));
		}
	'''
}

interface InterfaceGenerator extends Generator {
}

interface ClassGenerator extends Generator {
}
