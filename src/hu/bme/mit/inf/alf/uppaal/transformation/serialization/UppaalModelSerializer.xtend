package hu.bme.mit.inf.alf.uppaal.transformation.serialization

import hu.bme.mit.inf.alf.uppaal.transformation.UppaalModelBuilder
import java.io.FileWriter
import java.io.IOException

/**
 * The class is responsible for serializing the UPPAAL model specified by the
 * UppaalModelBuilder, to an XML file, that can be loaded by the UPPAAL.
 * 
 * The class strongly depends on the UppaalModelBuilder, and its saveToXML
 * method should only be called, after the UPPAAL model transformation was done
 * by the UppaalModelBuilder and the ModelTraverser classes.
 * 
 * The serialization is done by specifying the format of the output in character
 * sequences, and each model element is inserted to its place. 
 * 
 * It can now serialize all the updates of each edge, and the global declarations as well. 
 * 
 * The class has only static fields and methods, because it does not store
 * anything.
 * 
 * @author Benedek Horvath, Bence Graics
 */
 
class UppaalModelSerializer {
	var static id1 = 0
	var static id2 = 0
	/**
	 * Save the UPPAAL model specified by the UppaalModelBuilder to an XML file,
	 * denoted by its file path. The created XML file can be loaded by the
	 * UPPAAL.
	 * 
	 * @param filepath
	 *            The path for the output file. It contains the file name also,
	 *            except for the file extension.
	 */
	def static saveToXML(String filepath) {
		try {
			var fw = new FileWriter(filepath + ".xml")
			val header = createHeader
			val body = createTemplate
			val footer = createFooter
			fw.write(header + body.toString + footer)
			fw.close
			id1 = id2 = 0;
			// information message, about the completion of the transformation.
			println("Transformation has been finished.")
		} catch (IOException ex) {
			System.err.println("An error occurred, while creating the XML file. " + ex.message)
		}
	}
	
	/**
	 * Create the header and the beginning of the XML file, that contains 
	 * the declaration of the top-level UPPAAL module (NTA) and the global 
	 * declarations as well.
	 * 
	 * @return The header of the XML file in a char sequence.
	 */
	def static createHeader() '''
		<?xml version="1.0" encoding="utf-8"?>
		<!DOCTYPE nta PUBLIC '-//Uppaal Team//DTD Flat System 1.1//EN' 'http://www.it.uu.se/research/group/darts/uppaal/flat-1_1.dtd'>
		<nta>
		<declaration>«FOR declaration : UppaalModelBuilder.getInstance.NTA.globalDeclarations.declaration SEPARATOR "\n"»
		«declaration.exp»
		«ENDFOR»</declaration>
	'''
	
	/**
	 * Create the main part of the XML file: the Template, and locations and the 
	 * edges within the Template. All the data for the serialization are fetched 
	 * from the UppaalModelBuilder.
	 * 
	 * @return The main part of the XML file in a char sequence.
	 */
	def static createTemplate() '''
		«FOR template : UppaalModelBuilder.instance.templates SEPARATOR "\n"»
		<template>
		<name>«template.name»</name>
		<declaration>«FOR declaration : template.declarations.declaration SEPARATOR "\n"»
		«declaration.exp»
		«ENDFOR»</declaration>
			
		«FOR location : template.location SEPARATOR "\n"»
		<location id="«location.name»">
		<name>«location.name»</name>		
		«IF !(location.invariant == null)»<label kind="invariant">«location.invariant.exp»</label>«ENDIF»
		«IF !(location.comment == null)»<label kind="comments">«location.comment»</label>«ENDIF»
		«IF (location.locationTimeKind.literal.equals("COMMITED"))»<committed/>«ENDIF»
		«IF (location.locationTimeKind.literal.equals("URGENT"))»<urgent/>«ENDIF»
		</location>
		«ENDFOR»
		<init ref="«template.init.name»"/>
			
		«FOR transition : template.edge SEPARATOR "\n"»
		<transition>
		<source ref="«transition.source.name»"/>
		<target ref="«transition.target.name»"/>
		«IF !(transition.guard == null)»<label kind="guard">«transition.guard.exp.replaceAll("&&", "&amp;&amp;")»</label>«ENDIF»
		«IF !(transition.synchronization == null)»<label kind="synchronisation">«transition.synchronization.channelExpression.exp»«transition.synchronization.kind.literal»</label>«ENDIF»
		«IF !(transition.update == null)»<label kind="assignment">
		«FOR anUpdate : transition.update SEPARATOR ", "» 
		«anUpdate.exp»
		«ENDFOR»		
		</label>
		«ENDIF»
		«IF !(transition.comment == null)»<label kind="comments">«transition.comment»</label>«ENDIF»
		
		</transition>
		«ENDFOR»
		</template>
		«ENDFOR»
	'''
	 
	
	/**
	 * Create the footer of the XML file, which contains the instantiation of 
	 * the recently created Template. The instance of the Template is called
	 * "Process" in this implementation.
	 * 
	 * @return The footer of the XML file in a char sequence.
	 */
	def static createFooter() '''		
		<system>
		«FOR template : UppaalModelBuilder.instance.templates SEPARATOR "\n"»
		Process_«template.name» = «template.name»();
		«ENDFOR»		
		system 
		«FOR template : UppaalModelBuilder.instance.templates SEPARATOR ", "»
		Process_«template.name»
		«ENDFOR»;
		</system>
		</nta>
	'''

}
