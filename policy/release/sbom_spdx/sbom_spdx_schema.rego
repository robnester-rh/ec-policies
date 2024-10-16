package release.sbom_spdx

import rego.v1

# https://github.com/RedHatProductSecurity/security-data-guidelines/blob/main/sbom/spdx-2.3-schema.json
schema_2_3 := {
	"$schema": "http://json-schema.org/draft-07/schema#",
	"$id": "http://spdx.org/rdf/terms/2.3",
	"title": "SPDX 2.3",
	"type": "object",
	"properties": {
		"SPDXID": {
			"type": "string",
			"description": "Uniquely identify any element in an SPDX document which may be referenced by other elements.",
		},
		"annotations": {
			"description": "Provide additional information about an SpdxElement.",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"annotationDate": {
						"description": "Identify when the comment was made. This is to be specified according to the combined date and time in the UTC format, as specified in the ISO 8601 standard.",
						"type": "string",
					},
					"annotationType": {
						"description": "Type of the annotation.",
						"type": "string",
						"enum": ["OTHER", "REVIEW"],
					},
					"annotator": {
						"description": "This field identifies the person, organization, or tool that has commented on a file, package, snippet, or the entire document.",
						"type": "string",
					},
					"comment": {"type": "string"},
				},
				"required": ["annotationDate", "annotationType", "annotator", "comment"],
				"additionalProperties": false,
				"description": "An Annotation is a comment on an SpdxItem by an agent.",
			},
		},
		"comment": {"type": "string"},
		"creationInfo": {
			"type": "object",
			"properties": {
				"comment": {"type": "string"},
				"created": {
					"description": "Identify when the SPDX document was originally created. The date is to be specified according to combined date and time in UTC format as specified in ISO 8601 standard.",
					"type": "string",
				},
				"creators": {
					"description": "Identify who (or what, in the case of a tool) created the SPDX document. If the SPDX document was created by an individual, indicate the person's name. If the SPDX document was created on behalf of a company or organization, indicate the entity name. If the SPDX document was created using a software tool, indicate the name and version for that tool. If multiple participants or tools were involved, use multiple instances of this field. Person name or organization name may be designated as “anonymous” if appropriate.",
					"minItems": 1,
					"type": "array",
					"items": {
						"description": "Identify who (or what, in the case of a tool) created the SPDX document. If the SPDX document was created by an individual, indicate the person's name. If the SPDX document was created on behalf of a company or organization, indicate the entity name. If the SPDX document was created using a software tool, indicate the name and version for that tool. If multiple participants or tools were involved, use multiple instances of this field. Person name or organization name may be designated as “anonymous” if appropriate.",
						"type": "string",
					},
				},
				"licenseListVersion": {
					"description": "An optional field for creators of the SPDX file to provide the version of the SPDX License List used when the SPDX file was created.",
					"type": "string",
				},
			},
			"required": ["created", "creators"],
			"additionalProperties": false,
			"description": "One instance is required for each SPDX file produced. It provides the necessary information for forward and backward compatibility for processing tools.",
		},
		"dataLicense": {
			"description": "License expression for dataLicense. See SPDX Annex D for the license expression syntax.  Compliance with the SPDX specification includes populating the SPDX fields therein with data related to such fields (\"SPDX-Metadata\"). The SPDX specification contains numerous fields where an SPDX document creator may provide relevant explanatory text in SPDX-Metadata. Without opining on the lawfulness of \"database rights\" (in jurisdictions where applicable), such explanatory text is copyrightable subject matter in most Berne Convention countries. By using the SPDX specification, or any portion hereof, you hereby agree that any copyright rights (as determined by your jurisdiction) in any SPDX-Metadata, including without limitation explanatory text, shall be subject to the terms of the Creative Commons CC0 1.0 Universal license. For SPDX-Metadata not containing any copyright rights, you hereby agree and acknowledge that the SPDX-Metadata is provided to you \"as-is\" and without any representations or warranties of any kind concerning the SPDX-Metadata, express, implied, statutory or otherwise, including without limitation warranties of title, merchantability, fitness for a particular purpose, non-infringement, or the absence of latent or other defects, accuracy, or the presence or absence of errors, whether or not discoverable, all to the greatest extent permissible under applicable law.",
			"type": "string",
		},
		"externalDocumentRefs": {
			"description": "Identify any external SPDX documents referenced within this SPDX document.",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"checksum": {
						"type": "object",
						"properties": {
							"algorithm": {
								"description": "Identifies the algorithm used to produce the subject Checksum. Currently, SHA-1 is the only supported algorithm. It is anticipated that other algorithms will be supported at a later time.",
								"type": "string",
								"enum": ["SHA1", "BLAKE3", "SHA3-384", "SHA256", "SHA384", "BLAKE2b-512", "BLAKE2b-256", "SHA3-512", "MD2", "ADLER32", "MD4", "SHA3-256", "BLAKE2b-384", "SHA512", "MD6", "MD5", "SHA224"],
							},
							"checksumValue": {
								"description": "The checksumValue property provides a lower case hexidecimal encoded digest value produced using a specific algorithm.",
								"type": "string",
							},
						},
						"required": ["algorithm", "checksumValue"],
						"additionalProperties": false,
						"description": "A Checksum is value that allows the contents of a file to be authenticated. Even small changes to the content of the file will change its checksum. This class allows the results of a variety of checksum and cryptographic message digest algorithms to be represented.",
					},
					"externalDocumentId": {
						"description": "externalDocumentId is a string containing letters, numbers, ., - and/or + which uniquely identifies an external document within this document.",
						"type": "string",
					},
					"spdxDocument": {
						"description": "SPDX ID for SpdxDocument.  A property containing an SPDX document.",
						"type": "string",
					},
				},
				"required": ["checksum", "externalDocumentId", "spdxDocument"],
				"additionalProperties": false,
				"description": "Information about an external SPDX document reference including the checksum. This allows for verification of the external references.",
			},
		},
		"hasExtractedLicensingInfos": {
			"description": "Indicates that a particular ExtractedLicensingInfo was defined in the subject SpdxDocument.",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"comment": {"type": "string"},
					"crossRefs": {
						"description": "Cross Reference Detail for a license SeeAlso URL",
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"isLive": {
									"description": "Indicate a URL is still a live accessible location on the public internet",
									"type": "boolean",
								},
								"isValid": {
									"description": "True if the URL is a valid well formed URL",
									"type": "boolean",
								},
								"isWayBackLink": {
									"description": "True if the License SeeAlso URL points to a Wayback archive",
									"type": "boolean",
								},
								"match": {
									"description": "Status of a License List SeeAlso URL reference if it refers to a website that matches the license text.",
									"type": "string",
								},
								"order": {
									"description": "The ordinal order of this element within a list",
									"type": "integer",
								},
								"timestamp": {
									"description": "Timestamp",
									"type": "string",
								},
								"url": {
									"description": "URL Reference",
									"type": "string",
								},
							},
							"required": ["url"],
							"additionalProperties": false,
							"description": "Cross reference details for the a URL reference",
						},
					},
					"extractedText": {
						"description": "Provide a copy of the actual text of the license reference extracted from the package, file or snippet that is associated with the License Identifier to aid in future analysis.",
						"type": "string",
					},
					"licenseId": {
						"description": "A human readable short form license identifier for a license. The license ID is either on the standard license list or the form \"LicenseRef-[idString]\" where [idString] is a unique string containing letters, numbers, \".\" or \"-\".  When used within a license expression, the license ID can optionally include a reference to an external document in the form \"DocumentRef-[docrefIdString]:LicenseRef-[idString]\" where docRefIdString is an ID for an external document reference.",
						"type": "string",
					},
					"name": {
						"description": "Identify name of this SpdxElement.",
						"type": "string",
					},
					"seeAlsos": {
						"type": "array",
						"items": {"type": "string"},
					},
				},
				"required": ["extractedText", "licenseId"],
				"additionalProperties": false,
				"description": "An ExtractedLicensingInfo represents a license or licensing notice that was found in a package, file or snippet. Any license text that is recognized as a license may be represented as a License rather than an ExtractedLicensingInfo.",
			},
		},
		"name": {
			"description": "Identify name of this SpdxElement.",
			"type": "string",
		},
		"revieweds": {
			"description": "Reviewed",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"comment": {"type": "string"},
					"reviewDate": {
						"description": "The date and time at which the SpdxDocument was reviewed. This value must be in UTC and have 'Z' as its timezone indicator.",
						"type": "string",
					},
					"reviewer": {
						"description": "The name and, optionally, contact information of the person who performed the review. Values of this property must conform to the agent and tool syntax.  The reviewer property is deprecated in favor of Annotation with an annotationType review.",
						"type": "string",
					},
				},
				"required": ["reviewDate"],
				"additionalProperties": false,
				"description": "This class has been deprecated in favor of an Annotation with an Annotation type of review.",
			},
		},
		"spdxVersion": {
			"description": "Provide a reference number that can be used to understand how to parse and interpret the rest of the file. It will enable both future changes to the specification and to support backward compatibility. The version number consists of a major and minor version indicator. The major field will be incremented when incompatible changes between versions are made (one or more sections are created, modified or deleted). The minor field will be incremented when backwards compatible changes are made.",
			"type": "string",
		},
		"documentNamespace": {
			"type": "string",
			"description": "The URI provides an unambiguous mechanism for other SPDX documents to reference SPDX elements within this SPDX document.",
		},
		"documentDescribes": {
			"description": "Packages, files and/or Snippets described by this SPDX document",
			"type": "array",
			"items": {
				"type": "string",
				"description": "SPDX ID for each Package, File, or Snippet.",
			},
		},
		"packages": {
			"description": "Packages referenced in the SPDX document",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"SPDXID": {
						"type": "string",
						"description": "Uniquely identify any element in an SPDX document which may be referenced by other elements.",
					},
					"annotations": {
						"description": "Provide additional information about an SpdxElement.",
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"annotationDate": {
									"description": "Identify when the comment was made. This is to be specified according to the combined date and time in the UTC format, as specified in the ISO 8601 standard.",
									"type": "string",
								},
								"annotationType": {
									"description": "Type of the annotation.",
									"type": "string",
									"enum": ["OTHER", "REVIEW"],
								},
								"annotator": {
									"description": "This field identifies the person, organization, or tool that has commented on a file, package, snippet, or the entire document.",
									"type": "string",
								},
								"comment": {"type": "string"},
							},
							"required": ["annotationDate", "annotationType", "annotator", "comment"],
							"additionalProperties": false,
							"description": "An Annotation is a comment on an SpdxItem by an agent.",
						},
					},
					"attributionTexts": {
						"description": "This field provides a place for the SPDX data creator to record acknowledgements that may be required to be communicated in some contexts. This is not meant to include the actual complete license text (see licenseConculded and licenseDeclared), and may or may not include copyright notices (see also copyrightText). The SPDX data creator may use this field to record other acknowledgements, such as particular clauses from license texts, which may be necessary or desirable to reproduce.",
						"type": "array",
						"items": {
							"description": "This field provides a place for the SPDX data creator to record acknowledgements that may be required to be communicated in some contexts. This is not meant to include the actual complete license text (see licenseConculded and licenseDeclared), and may or may not include copyright notices (see also copyrightText). The SPDX data creator may use this field to record other acknowledgements, such as particular clauses from license texts, which may be necessary or desirable to reproduce.",
							"type": "string",
						},
					},
					"builtDate": {
						"description": "This field provides a place for recording the actual date the package was built.",
						"type": "string",
					},
					"checksums": {
						"description": "The checksum property provides a mechanism that can be used to verify that the contents of a File or Package have not changed.",
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"algorithm": {
									"description": "Identifies the algorithm used to produce the subject Checksum. Currently, SHA-1 is the only supported algorithm. It is anticipated that other algorithms will be supported at a later time.",
									"type": "string",
									"enum": ["SHA1", "BLAKE3", "SHA3-384", "SHA256", "SHA384", "BLAKE2b-512", "BLAKE2b-256", "SHA3-512", "MD2", "ADLER32", "MD4", "SHA3-256", "BLAKE2b-384", "SHA512", "MD6", "MD5", "SHA224"],
								},
								"checksumValue": {
									"description": "The checksumValue property provides a lower case hexidecimal encoded digest value produced using a specific algorithm.",
									"type": "string",
								},
							},
							"required": ["algorithm", "checksumValue"],
							"additionalProperties": false,
							"description": "A Checksum is value that allows the contents of a file to be authenticated. Even small changes to the content of the file will change its checksum. This class allows the results of a variety of checksum and cryptographic message digest algorithms to be represented.",
						},
					},
					"comment": {"type": "string"},
					"copyrightText": {
						"description": "The text of copyright declarations recited in the package, file or snippet.\n\nIf the copyrightText field is not present, it implies an equivalent meaning to NOASSERTION.",
						"type": "string",
					},
					"description": {
						"description": "Provides a detailed description of the package.",
						"type": "string",
					},
					"downloadLocation": {
						"description": "The URI at which this package is available for download. Private (i.e., not publicly reachable) URIs are acceptable as values of this property. The values http://spdx.org/rdf/terms#none and http://spdx.org/rdf/terms#noassertion may be used to specify that the package is not downloadable or that no attempt was made to determine its download location, respectively.",
						"type": "string",
					},
					"externalRefs": {
						"description": "An External Reference allows a Package to reference an external source of additional information, metadata, enumerations, asset identifiers, or downloadable content believed to be relevant to the Package.",
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"comment": {"type": "string"},
								"referenceCategory": {
									"description": "Category for the external reference",
									"type": "string",
									"enum": ["OTHER", "PERSISTENT-ID", "SECURITY", "PACKAGE-MANAGER"],
								},
								"referenceLocator": {
									"description": "The unique string with no spaces necessary to access the package-specific information, metadata, or content within the target location. The format of the locator is subject to constraints defined by the <type>.",
									"type": "string",
								},
								"referenceType": {
									"description": "Type of the external reference. These are definined in an appendix in the SPDX specification.",
									"type": "string",
								},
							},
							"required": ["referenceCategory", "referenceLocator", "referenceType"],
							"additionalProperties": false,
							"description": "An External Reference allows a Package to reference an external source of additional information, metadata, enumerations, asset identifiers, or downloadable content believed to be relevant to the Package.",
						},
					},
					"filesAnalyzed": {
						"description": "Indicates whether the file content of this package has been available for or subjected to analysis when creating the SPDX document. If false indicates packages that represent metadata or URI references to a project, product, artifact, distribution or a component. If set to false, the package must not contain any files.",
						"type": "boolean",
					},
					"hasFiles": {
						"description": "Indicates that a particular file belongs to a package.",
						"type": "array",
						"items": {
							"description": "SPDX ID for File.  Indicates that a particular file belongs to a package.",
							"type": "string",
						},
					},
					"homepage": {"type": "string"},
					"licenseComments": {
						"description": "The licenseComments property allows the preparer of the SPDX document to describe why the licensing in spdx:licenseConcluded was chosen.",
						"type": "string",
					},
					"licenseConcluded": {
						"description": "License expression for licenseConcluded. See SPDX Annex D for the license expression syntax.  The licensing that the preparer of this SPDX document has concluded, based on the evidence, actually applies to the SPDX Item.\n\nIf the licenseConcluded field is not present for an SPDX Item, it implies an equivalent meaning to NOASSERTION.",
						"type": "string",
					},
					"licenseDeclared": {
						"description": "License expression for licenseDeclared. See SPDX Annex D for the license expression syntax.  The licensing that the creators of the software in the package, or the packager, have declared. Declarations by the original software creator should be preferred, if they exist.",
						"type": "string",
					},
					"licenseInfoFromFiles": {
						"description": "The licensing information that was discovered directly within the package. There will be an instance of this property for each distinct value of alllicenseInfoInFile properties of all files contained in the package.\n\nIf the licenseInfoFromFiles field is not present for a package and filesAnalyzed property for that same pacakge is true or omitted, it implies an equivalent meaning to NOASSERTION.",
						"type": "array",
						"items": {
							"description": "License expression for licenseInfoFromFiles. See SPDX Annex D for the license expression syntax.  The licensing information that was discovered directly within the package. There will be an instance of this property for each distinct value of alllicenseInfoInFile properties of all files contained in the package.\n\nIf the licenseInfoFromFiles field is not present for a package and filesAnalyzed property for that same pacakge is true or omitted, it implies an equivalent meaning to NOASSERTION.",
							"type": "string",
						},
					},
					"name": {
						"description": "Identify name of this SpdxElement.",
						"type": "string",
					},
					"originator": {
						"description": "The name and, optionally, contact information of the person or organization that originally created the package. Values of this property must conform to the agent and tool syntax.",
						"type": "string",
					},
					"packageFileName": {
						"description": "The base name of the package file name. For example, zlib-1.2.5.tar.gz.",
						"type": "string",
					},
					"packageVerificationCode": {
						"type": "object",
						"properties": {
							"packageVerificationCodeExcludedFiles": {
								"description": "A file that was excluded when calculating the package verification code. This is usually a file containing SPDX data regarding the package. If a package contains more than one SPDX file all SPDX files must be excluded from the package verification code. If this is not done it would be impossible to correctly calculate the verification codes in both files.",
								"type": "array",
								"items": {
									"description": "A file that was excluded when calculating the package verification code. This is usually a file containing SPDX data regarding the package. If a package contains more than one SPDX file all SPDX files must be excluded from the package verification code. If this is not done it would be impossible to correctly calculate the verification codes in both files.",
									"type": "string",
								},
							},
							"packageVerificationCodeValue": {
								"description": "The actual package verification code as a hex encoded value.",
								"type": "string",
							},
						},
						"required": ["packageVerificationCodeValue"],
						"additionalProperties": false,
						"description": "A manifest based verification code (the algorithm is defined in section 4.7 of the full specification) of the SPDX Item. This allows consumers of this data and/or database to determine if an SPDX item they have in hand is identical to the SPDX item from which the data was produced. This algorithm works even if the SPDX document is included in the SPDX item.",
					},
					"primaryPackagePurpose": {
						"description": "This field provides information about the primary purpose of the identified package. Package Purpose is intrinsic to how the package is being used rather than the content of the package.",
						"type": "string",
						"enum": ["OTHER", "INSTALL", "ARCHIVE", "FIRMWARE", "APPLICATION", "FRAMEWORK", "LIBRARY", "CONTAINER", "SOURCE", "DEVICE", "OPERATING_SYSTEM", "FILE"],
					},
					"releaseDate": {
						"description": "This field provides a place for recording the date the package was released.",
						"type": "string",
					},
					"sourceInfo": {
						"description": "Allows the producer(s) of the SPDX document to describe how the package was acquired and/or changed from the original source.",
						"type": "string",
					},
					"summary": {
						"description": "Provides a short description of the package.",
						"type": "string",
					},
					"supplier": {
						"description": "The name and, optionally, contact information of the person or organization who was the immediate supplier of this package to the recipient. The supplier may be different than originator when the software has been repackaged. Values of this property must conform to the agent and tool syntax.",
						"type": "string",
					},
					"validUntilDate": {
						"description": "This field provides a place for recording the end of the support period for a package from the supplier.",
						"type": "string",
					},
					"versionInfo": {
						"description": "Provides an indication of the version of the package that is described by this SpdxDocument.",
						"type": "string",
					},
				},
				"required": ["SPDXID", "downloadLocation", "name"],
				"additionalProperties": false,
			},
		},
		"files": {
			"description": "Files referenced in the SPDX document",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"SPDXID": {
						"type": "string",
						"description": "Uniquely identify any element in an SPDX document which may be referenced by other elements.",
					},
					"annotations": {
						"description": "Provide additional information about an SpdxElement.",
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"annotationDate": {
									"description": "Identify when the comment was made. This is to be specified according to the combined date and time in the UTC format, as specified in the ISO 8601 standard.",
									"type": "string",
								},
								"annotationType": {
									"description": "Type of the annotation.",
									"type": "string",
									"enum": ["OTHER", "REVIEW"],
								},
								"annotator": {
									"description": "This field identifies the person, organization, or tool that has commented on a file, package, snippet, or the entire document.",
									"type": "string",
								},
								"comment": {"type": "string"},
							},
							"required": ["annotationDate", "annotationType", "annotator", "comment"],
							"additionalProperties": false,
							"description": "An Annotation is a comment on an SpdxItem by an agent.",
						},
					},
					"artifactOfs": {
						"description": "Indicates the project in which the SpdxElement originated. Tools must preserve doap:homepage and doap:name properties and the URI (if one is known) of doap:Project resources that are values of this property. All other properties of doap:Projects are not directly supported by SPDX and may be dropped when translating to or from some SPDX formats.",
						"type": "array",
						"items": {"type": "object"},
					},
					"attributionTexts": {
						"description": "This field provides a place for the SPDX data creator to record acknowledgements that may be required to be communicated in some contexts. This is not meant to include the actual complete license text (see licenseConculded and licenseDeclared), and may or may not include copyright notices (see also copyrightText). The SPDX data creator may use this field to record other acknowledgements, such as particular clauses from license texts, which may be necessary or desirable to reproduce.",
						"type": "array",
						"items": {
							"description": "This field provides a place for the SPDX data creator to record acknowledgements that may be required to be communicated in some contexts. This is not meant to include the actual complete license text (see licenseConculded and licenseDeclared), and may or may not include copyright notices (see also copyrightText). The SPDX data creator may use this field to record other acknowledgements, such as particular clauses from license texts, which may be necessary or desirable to reproduce.",
							"type": "string",
						},
					},
					"checksums": {
						"description": "The checksum property provides a mechanism that can be used to verify that the contents of a File or Package have not changed.",
						"minItems": 1,
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"algorithm": {
									"description": "Identifies the algorithm used to produce the subject Checksum. Currently, SHA-1 is the only supported algorithm. It is anticipated that other algorithms will be supported at a later time.",
									"type": "string",
									"enum": ["SHA1", "BLAKE3", "SHA3-384", "SHA256", "SHA384", "BLAKE2b-512", "BLAKE2b-256", "SHA3-512", "MD2", "ADLER32", "MD4", "SHA3-256", "BLAKE2b-384", "SHA512", "MD6", "MD5", "SHA224"],
								},
								"checksumValue": {
									"description": "The checksumValue property provides a lower case hexidecimal encoded digest value produced using a specific algorithm.",
									"type": "string",
								},
							},
							"required": ["algorithm", "checksumValue"],
							"additionalProperties": false,
							"description": "A Checksum is value that allows the contents of a file to be authenticated. Even small changes to the content of the file will change its checksum. This class allows the results of a variety of checksum and cryptographic message digest algorithms to be represented.",
						},
					},
					"comment": {"type": "string"},
					"copyrightText": {
						"description": "The text of copyright declarations recited in the package, file or snippet.\n\nIf the copyrightText field is not present, it implies an equivalent meaning to NOASSERTION.",
						"type": "string",
					},
					"fileContributors": {
						"description": "This field provides a place for the SPDX file creator to record file contributors. Contributors could include names of copyright holders and/or authors who may not be copyright holders yet contributed to the file content.",
						"type": "array",
						"items": {
							"description": "This field provides a place for the SPDX file creator to record file contributors. Contributors could include names of copyright holders and/or authors who may not be copyright holders yet contributed to the file content.",
							"type": "string",
						},
					},
					"fileDependencies": {
						"description": "This field is deprecated since SPDX 2.0 in favor of using Section 7 which provides more granularity about relationships.",
						"type": "array",
						"items": {
							"description": "SPDX ID for File.  This field is deprecated since SPDX 2.0 in favor of using Section 7 which provides more granularity about relationships.",
							"type": "string",
						},
					},
					"fileName": {
						"description": "The name of the file relative to the root of the package.",
						"type": "string",
					},
					"fileTypes": {
						"description": "The type of the file.",
						"type": "array",
						"items": {
							"description": "The type of the file.",
							"type": "string",
							"enum": ["OTHER", "DOCUMENTATION", "IMAGE", "VIDEO", "ARCHIVE", "SPDX", "APPLICATION", "SOURCE", "BINARY", "TEXT", "AUDIO"],
						},
					},
					"licenseComments": {
						"description": "The licenseComments property allows the preparer of the SPDX document to describe why the licensing in spdx:licenseConcluded was chosen.",
						"type": "string",
					},
					"licenseConcluded": {
						"description": "License expression for licenseConcluded. See SPDX Annex D for the license expression syntax.  The licensing that the preparer of this SPDX document has concluded, based on the evidence, actually applies to the SPDX Item.\n\nIf the licenseConcluded field is not present for an SPDX Item, it implies an equivalent meaning to NOASSERTION.",
						"type": "string",
					},
					"licenseInfoInFiles": {
						"description": "Licensing information that was discovered directly in the subject file. This is also considered a declared license for the file.\n\nIf the licenseInfoInFile field is not present for a file, it implies an equivalent meaning to NOASSERTION.",
						"type": "array",
						"items": {
							"description": "License expression for licenseInfoInFile. See SPDX Annex D for the license expression syntax.  Licensing information that was discovered directly in the subject file. This is also considered a declared license for the file.\n\nIf the licenseInfoInFile field is not present for a file, it implies an equivalent meaning to NOASSERTION.",
							"type": "string",
						},
					},
					"noticeText": {
						"description": "This field provides a place for the SPDX file creator to record potential legal notices found in the file. This may or may not include copyright statements.",
						"type": "string",
					},
				},
				"required": ["SPDXID", "checksums", "fileName"],
				"additionalProperties": false,
			},
		},
		"snippets": {
			"description": "Snippets referenced in the SPDX document",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"SPDXID": {
						"type": "string",
						"description": "Uniquely identify any element in an SPDX document which may be referenced by other elements.",
					},
					"annotations": {
						"description": "Provide additional information about an SpdxElement.",
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"annotationDate": {
									"description": "Identify when the comment was made. This is to be specified according to the combined date and time in the UTC format, as specified in the ISO 8601 standard.",
									"type": "string",
								},
								"annotationType": {
									"description": "Type of the annotation.",
									"type": "string",
									"enum": ["OTHER", "REVIEW"],
								},
								"annotator": {
									"description": "This field identifies the person, organization, or tool that has commented on a file, package, snippet, or the entire document.",
									"type": "string",
								},
								"comment": {"type": "string"},
							},
							"required": ["annotationDate", "annotationType", "annotator", "comment"],
							"additionalProperties": false,
							"description": "An Annotation is a comment on an SpdxItem by an agent.",
						},
					},
					"attributionTexts": {
						"description": "This field provides a place for the SPDX data creator to record acknowledgements that may be required to be communicated in some contexts. This is not meant to include the actual complete license text (see licenseConculded and licenseDeclared), and may or may not include copyright notices (see also copyrightText). The SPDX data creator may use this field to record other acknowledgements, such as particular clauses from license texts, which may be necessary or desirable to reproduce.",
						"type": "array",
						"items": {
							"description": "This field provides a place for the SPDX data creator to record acknowledgements that may be required to be communicated in some contexts. This is not meant to include the actual complete license text (see licenseConculded and licenseDeclared), and may or may not include copyright notices (see also copyrightText). The SPDX data creator may use this field to record other acknowledgements, such as particular clauses from license texts, which may be necessary or desirable to reproduce.",
							"type": "string",
						},
					},
					"comment": {"type": "string"},
					"copyrightText": {
						"description": "The text of copyright declarations recited in the package, file or snippet.\n\nIf the copyrightText field is not present, it implies an equivalent meaning to NOASSERTION.",
						"type": "string",
					},
					"licenseComments": {
						"description": "The licenseComments property allows the preparer of the SPDX document to describe why the licensing in spdx:licenseConcluded was chosen.",
						"type": "string",
					},
					"licenseConcluded": {
						"description": "License expression for licenseConcluded. See SPDX Annex D for the license expression syntax.  The licensing that the preparer of this SPDX document has concluded, based on the evidence, actually applies to the SPDX Item.\n\nIf the licenseConcluded field is not present for an SPDX Item, it implies an equivalent meaning to NOASSERTION.",
						"type": "string",
					},
					"licenseInfoInSnippets": {
						"description": "Licensing information that was discovered directly in the subject snippet. This is also considered a declared license for the snippet.\n\nIf the licenseInfoInSnippet field is not present for a snippet, it implies an equivalent meaning to NOASSERTION.",
						"type": "array",
						"items": {
							"description": "License expression for licenseInfoInSnippet. See SPDX Annex D for the license expression syntax.  Licensing information that was discovered directly in the subject snippet. This is also considered a declared license for the snippet.\n\nIf the licenseInfoInSnippet field is not present for a snippet, it implies an equivalent meaning to NOASSERTION.",
							"type": "string",
						},
					},
					"name": {
						"description": "Identify name of this SpdxElement.",
						"type": "string",
					},
					"ranges": {
						"description": "This field defines the byte range in the original host file (in X.2) that the snippet information applies to",
						"minItems": 1,
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"endPointer": {
									"type": "object",
									"properties": {
										"reference": {
											"description": "SPDX ID for File",
											"type": "string",
										},
										"offset": {
											"type": "integer",
											"description": "Byte offset in the file",
										},
										"lineNumber": {
											"type": "integer",
											"description": "line number offset in the file",
										},
									},
									"required": ["reference"],
									"additionalProperties": false,
								},
								"startPointer": {
									"type": "object",
									"properties": {
										"reference": {
											"description": "SPDX ID for File",
											"type": "string",
										},
										"offset": {
											"type": "integer",
											"description": "Byte offset in the file",
										},
										"lineNumber": {
											"type": "integer",
											"description": "line number offset in the file",
										},
									},
									"required": ["reference"],
									"additionalProperties": false,
								},
							},
							"required": ["endPointer", "startPointer"],
							"additionalProperties": false,
						},
					},
					"snippetFromFile": {
						"description": "SPDX ID for File.  File containing the SPDX element (e.g. the file contaning a snippet).",
						"type": "string",
					},
				},
				"required": ["SPDXID", "name", "ranges", "snippetFromFile"],
				"additionalProperties": false,
			},
		},
		"relationships": {
			"description": "Relationships referenced in the SPDX document",
			"type": "array",
			"items": {
				"type": "object",
				"properties": {
					"spdxElementId": {
						"type": "string",
						"description": "Id to which the SPDX element is related",
					},
					"comment": {"type": "string"},
					"relatedSpdxElement": {
						"description": "SPDX ID for SpdxElement.  A related SpdxElement.",
						"type": "string",
					},
					"relationshipType": {
						"description": "Describes the type of relationship between two SPDX elements.",
						"type": "string",
						"enum": ["VARIANT_OF", "COPY_OF", "PATCH_FOR", "TEST_DEPENDENCY_OF", "CONTAINED_BY", "DATA_FILE_OF", "OPTIONAL_COMPONENT_OF", "ANCESTOR_OF", "GENERATES", "CONTAINS", "OPTIONAL_DEPENDENCY_OF", "FILE_ADDED", "REQUIREMENT_DESCRIPTION_FOR", "DEV_DEPENDENCY_OF", "DEPENDENCY_OF", "BUILD_DEPENDENCY_OF", "DESCRIBES", "PREREQUISITE_FOR", "HAS_PREREQUISITE", "PROVIDED_DEPENDENCY_OF", "DYNAMIC_LINK", "DESCRIBED_BY", "METAFILE_OF", "DEPENDENCY_MANIFEST_OF", "PATCH_APPLIED", "RUNTIME_DEPENDENCY_OF", "TEST_OF", "TEST_TOOL_OF", "DEPENDS_ON", "SPECIFICATION_FOR", "FILE_MODIFIED", "DISTRIBUTION_ARTIFACT", "AMENDS", "DOCUMENTATION_OF", "GENERATED_FROM", "STATIC_LINK", "OTHER", "BUILD_TOOL_OF", "TEST_CASE_OF", "PACKAGE_OF", "DESCENDANT_OF", "FILE_DELETED", "EXPANDED_FROM_ARCHIVE", "DEV_TOOL_OF", "EXAMPLE_OF"],
					},
				},
				"required": ["spdxElementId", "relatedSpdxElement", "relationshipType"],
				"additionalProperties": false,
			},
		},
	},
	"required": ["SPDXID", "creationInfo", "dataLicense", "name", "spdxVersion"],
	"additionalProperties": false,
}