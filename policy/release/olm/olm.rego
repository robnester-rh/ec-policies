#
# METADATA
# title: OLM
# description: >-
#   Checks for Operator Lifecycle Manager (OLM) bundles.
#
package olm

import rego.v1

import data.lib
import data.lib.image
import data.lib.json as j

manifestv1 := "operators.operatorframework.io.bundle.manifests.v1"

# METADATA
# title: ClusterServiceVersion semver format
# description: >-
#   Check the `spec.version` value in the ClusterServiceVersion manifest of the OLM bundle uses a
#   properly formatted semver.
# custom:
#   short_name: csv_semver_format
#   failure_msg: 'The ClusterServiceVersion spec.version, %q, is not a valid semver'
#   solution: >-
#     Update the ClusterServiceVersion manifest of the OLM bundle to set the spec.version value to
#     a valid semver.
#   collections:
#   - redhat
#
deny contains result if {
	some manifest in _csv_manifests
	version := object.get(manifest, ["spec", "version"], "<MISSING>")
	not semver.is_valid(version)
	result := lib.result_helper(rego.metadata.chain(), [version])
}

# METADATA
# title: Unpinned images in OLM bundle
# description: >-
#   Check the OLM bundle image for the presence of unpinned image references.
#   Unpinned image pull references are references to images found in
#   link:https://osbs.readthedocs.io/en/latest/users.html#pullspec-locations[varying
#   locations] that do not contain a digest -- uniquely identifying the version of
#   the image being pulled.
# custom:
#   short_name: unpinned_references
#   failure_msg: The %q image reference is not pinned at %s.
#   solution: >-
#     Update the OLM bundle replacing the unpinned image reference with pinned image
#     reference. Pinned image reference contains the image digest.
#   collections:
#   - redhat
#
deny contains result if {
	some manifest in _csv_manifests

	some i in all_image_ref(manifest)
	i.ref.digest == "" # unpinned image references have no digest

	result := lib.result_helper_with_term(rego.metadata.chain(), [image.str(i.ref), i.path], image.str(i.ref))
}

# METADATA
# title: Feature annotations have expected value
# description: >-
#   Check the feature annotations in the ClusterServiceVersion manifest of the OLM bundle. All of
#   required feature annotations must be present and set to either the string `"true"` or the string
#   `"false"`. The list of feature annotations can be customize via the
#   `required_olm_features_annotations` rule data.
# custom:
#   short_name: feature_annotations_format
#   failure_msg: The annotation %q is either missing or has an unexpected value
#   solution: >-
#     Update the ClusterServiceVersion manifest of the OLM bundle to set the feature annotations
#     to the expected value.
#   collections:
#   - redhat
#
deny contains result if {
	some manifest in _csv_manifests
	some annotation in lib.rule_data("required_olm_features_annotations")
	value := object.get(manifest.metadata.annotations, annotation, "")
	not value in {"true", "false"}
	result := lib.result_helper_with_term(rego.metadata.chain(), [annotation], annotation)
}

# METADATA
# title: Subscription annotation has expected value
# description: >-
#   Check the value of the operators.openshift.io/valid-subscription annotation from the
#   ClusterServiceVersion manifest is in the expected format, i.e. JSON encoded non-empty array of
#   strings.
# custom:
#   short_name: subscriptions_annotation_format
#   failure_msg: "%s"
#   solution: >-
#     Update the ClusterServiceVersion manifest of the OLM bundle to set the subscription
#     annotation to the expected value.
#   collections:
#   - redhat
#   effective_on: 2024-04-18T00:00:00Z
#
deny contains result if {
	some e in _subscriptions_errors
	result := lib.result_helper_with_severity(rego.metadata.chain(), [e.message], e.severity)
}

# METADATA
# title: Required OLM feature annotations list provided
# description: >-
#   Confirm the `required_olm_features_annotations` rule data was provided, since it's
#   required by the policy rules in this package.
# custom:
#   short_name: required_olm_features_annotations_provided
#   failure_msg: "%s"
#   collections:
#   - redhat
#   - policy_data
#
deny contains result if {
	some e in _rule_data_errors
	result := lib.result_helper_with_severity(rego.metadata.chain(), [e.message], e.severity)
}

# METADATA
# title: Unpinned images in input snapshot
# description: >-
#   Check the input snapshot for the presence of unpinned image references.
#   Unpinned image pull references are references to images
#   that do not contain a digest -- uniquely identifying the version of
#   the image being pulled.
# custom:
#   short_name: unpinned_snapshot_references
#   failure_msg: The %q image reference is not pinned in the input snapshot.
#   solution: >-
#     Update the input snapshot replacing the unpinned image reference with pinned image
#     reference. Pinned image reference contains the image digest.
#   collections:
#   - redhat
#   effective_on: 2024-08-15T00:00:00Z
#
deny contains result if {
	_release_restrictions_apply

	input_image = image.parse(input.image.ref)
	components := input.snapshot.components
	some component in components
	parsed_image := image.parse(component.containerImage)
	parsed_image.repo == input_image.repo
	parsed_image.digest == "" # unpinned image references have no digest

	result := lib.result_helper_with_term(rego.metadata.chain(), [image.str(parsed_image)], image.str(parsed_image))
}

# METADATA
# title: Unable to access images in the input snapshot
# description: >-
#   Check the input snapshot and make sure all the images are accessible.
# custom:
#   short_name: inaccessible_snapshot_references
#   failure_msg: The %q image reference is not accessible in the input snapshot.
#   solution: >-
#     Ensure all images in the input snapshot are valid.
#   collections:
#   - redhat
#   effective_on: 2024-08-15T00:00:00Z
#
deny contains result if {
	_release_restrictions_apply

	components := input.snapshot.components
	some component in components
	not ec.oci.image_manifest(component.containerImage)
	result := lib.result_helper_with_term(rego.metadata.chain(), [component.containerImage], component.containerImage)
}

# METADATA
# title: Unmapped images in OLM bundle
# description: >-
#   Check the OLM bundle image for the presence of unmapped image references.
#   Unmapped image pull references are references to images found in
#   link:https://osbs.readthedocs.io/en/latest/users.html#pullspec-locations[varying
#   locations] that are either not in the RPA about to be released or not accessible
#   already.
# custom:
#   short_name: unmapped_references
#   failure_msg: The %q CSV image reference is not in the snapshot or accessible.
#   solution: >-
#     Add the missing image to the snapshot or check if the CSV pullspec
#     is valid and accessible.
#   collections:
#   - redhat
#   effective_on: 2024-08-15T00:00:00Z
#
deny contains result if {
	_release_restrictions_apply

	snapshot_components := input.snapshot.components
	component_images_digests := [component_image.digest |
		some component in snapshot_components
		component_image := image.parse(component.containerImage)
	]

	some manifest in _csv_manifests
	all_image_refs := all_image_ref(manifest)
	unmatched_image_refs := [image |
		some image in all_image_refs
		not image.ref.digest in component_images_digests
	]

	some unmatched_image in unmatched_image_refs
	not ec.oci.image_manifest(image.str(unmatched_image.ref))

	# regal ignore:line-length
	result := lib.result_helper_with_term(rego.metadata.chain(), [image.str(unmatched_image.ref)], image.str(unmatched_image.ref))
}

# METADATA
# title: Images referenced by OLM bundle are from allowed registries
# description: >-
#   Each image referenced by the OLM bundle should match an entry in the list of prefixes
#   defined by the rule data key `allowed_registry_prefixes` in your policy configuration.
# custom:
#   short_name: allowed_registries
#   failure_msg: The %q CSV image reference is not from an allowed registry.
#   solution: >-
#     Use image from an allowed registry, or modify your
#     xref:ec-cli:ROOT:configuration.adoc#_data_sources[policy configuration] to include additional registry prefixes.
#   collections:
#   - redhat
#   effective_on: 2024-09-01T00:00:00Z
#
deny contains result if {
	# The presence of expected rule_data verified in _rule_data_errors
	allowed_registry_prefixes := lib.rule_data("allowed_registry_prefixes")

	# Parse manifests from snapshot
	some csv_manifest in _csv_manifests

	# Parse image references from each manifest
	all_csv_images := all_image_ref(csv_manifest)

	some img in all_csv_images
	not _image_registry_allowed(img.ref.repo, allowed_registry_prefixes)

	img_str := image.str(img.ref)

	result := lib.result_helper_with_term(rego.metadata.chain(), [img_str], img.ref.repo)
}

_name(o) := n if {
	n := o.name
} else := "unnamed"

# Finds all image references and their locations (paths). Returns all image
# references (parsed into components) found in locations as specified by:
# regal ignore:line-length
# https://github.com/containerbuildsystem/operator-manifest/blob/f24cd9374f5ad9fed04f47701acffa16837d940e/README.md#pull-specifications
# and https://osbs.readthedocs.io/en/latest/users.html#pullspec-locations
all_image_ref(manifest) := [e |
	# NOTE: use comprehensions in here, trying to set a value for `imgs` that
	# could be undefined will lead to the whole block being undefined, i.e.
	# don't do:
	# [
	#	{
	#      "path": "manifest.metadata.annotations.containerImage",
	#      "ref":image.parse(manifest.metadata.annotations.containerImage)
	#   }
	# ]
	# as the components of manifest.metadata.annotations.containerImage could be undefined!
	some imgs in [
		[r |
			# regal ignore:prefer-snake-case
			some i, related in manifest.spec.relatedImages
			r := {"path": sprintf("spec.relatedImages[%d].image", [i]), "ref": image.parse(related.image)}
		],
		[r |
			# regal ignore:prefer-snake-case
			manifest.metadata.annotations.containerImage
			r := {
				"path": "annotations.containerImage",
				"ref": image.parse(manifest.metadata.annotations.containerImage),
			}
		],
		[r |
			some _, values in walk(manifest)
			some key, val in values.metadata.annotations
			some annotation in regex.split(`(,|;|\n|\s+)`, val)
			ref := image.parse(trim_space(annotation))
			ref.repo # ones that are parsed as image reference, detected by having "repo" property set
			r := {"path": sprintf("annotations[%q]", [key]), "ref": ref}
		],
		[r |
			some d, deployment in manifest.spec.install.spec.deployments
			some c, container in deployment.spec.template.spec.containers
			ref := image.parse(container.image)
			r := {
				"path": sprintf(
					"spec.install.spec.deployments[%d (%q)].spec.template.spec.containers[%d (%q)].image",
					[d, _name(deployment), c, _name(container)],
				),
				"ref": ref,
			}
		],
		[r |
			some d, deployment in manifest.spec.install.spec.deployments

			# regal ignore:prefer-snake-case
			some c, initContainer in deployment.spec.template.spec.initContainers
			ref := image.parse(initContainer.image)
			r := {
				"path": sprintf(
					"spec.install.spec.deployments[%d (%q)].spec.template.spec.initContainers[%d (%q)].image",
					[d, _name(deployment), c, _name(initContainer)],
				),
				"ref": ref,
			}
		],
		[r |
			some d, deployment in manifest.spec.install.spec.deployments
			some c, container in deployment.spec.template.spec.containers
			some e in container.env
			startswith(e.name, "RELATED_IMAGE_")
			ref := image.parse(e.value)
			r := {
				"path": sprintf(
					"spec.install.spec.deployments[%d (%q)].spec.template.spec.containers[%d (%q)].env[%q]",
					[d, _name(deployment), c, _name(container), e.name],
				),
				"ref": ref,
			}
		],
		[r |
			some d, deployment in manifest.spec.install.spec.deployments

			# regal ignore:prefer-snake-case
			some c, initContainer in deployment.spec.template.spec.initContainers
			some e in initContainer.env
			startswith(e.name, "RELATED_IMAGE_")
			ref := image.parse(e.value)
			r := {
				"path": sprintf(
					"spec.install.spec.deployments[%d (%q)].spec.template.spec.initContainers[%d (%q)].env[%q]",
					[d, _name(deployment), c, _name(initContainer), e.name],
				),
				"ref": ref,
			}
		],
	]
	some i in imgs

	e := {"ref": i.ref, "path": i.path}
]

# Returns the ClusterServiceVersion manifests found in the OLM bundle.
_csv_manifests contains manifest if {
	manifest_dir := input.image.config.Labels[manifestv1]

	some path, manifest in input.image.files

	# only consider files in the manifest path as determined by the OLM manifest v1 label
	startswith(path, manifest_dir)

	# only consider this API prefix, disregard the version
	# regal ignore:prefer-snake-case
	startswith(manifest.apiVersion, "operators.coreos.com/")

	# only consider CSV manifests
	manifest.kind == "ClusterServiceVersion"
}

# Verify allowed_registry_prefixes & required_olm_features_annotations are non-empty list of strings
_rule_data_errors contains error if {
	some rule_data_key in _rule_data_keys
	some e in j.validate_schema(
		lib.rule_data(rule_data_key),
		{
			"$schema": "http://json-schema.org/draft-07/schema#",
			"type": "array",
			"items": {"type": "string"},
			"uniqueItems": true,
			"minItems": 1,
		},
	)
	error := {
		"message": sprintf("Rule data %s has unexpected format: %s", [rule_data_key, e.message]),
		"severity": e.severity,
	}
}

_rule_data_keys := [
	"required_olm_features_annotations",
	"allowed_registry_prefixes",
]

_subscriptions_errors contains error if {
	some manifest in _csv_manifests
	not manifest.metadata.annotations[_subscription_annotation]
	error := {
		"message": sprintf("Value of %s annotation is missing", [_subscription_annotation]),
		"severity": "failure",
	}
}

_subscriptions_errors contains error if {
	some manifest in _csv_manifests
	subscription := manifest.metadata.annotations[_subscription_annotation]
	not json.is_valid(subscription)
	error := {
		"message": sprintf("Value of %s annotation is not valid JSON", [_subscription_annotation]),
		"severity": "failure",
	}
}

_subscriptions_errors contains error if {
	some manifest in _csv_manifests
	subscription := manifest.metadata.annotations[_subscription_annotation]
	some e in j.validate_schema(
		subscription,
		{
			"$schema": "http://json-schema.org/draft-07/schema#",
			"type": "array",
			"items": {"type": "string"},
			"uniqueItems": true,
			"minItems": 1,
		},
	)
	error := {
		"message": sprintf("Value of %s annotation is invalid: %s", [_subscription_annotation, e.message]),
		"severity": e.severity,
	}
}

_subscription_annotation := "operators.openshift.io/valid-subscription"

# We want these checks to apply only if we're doing a release.
default _release_restrictions_apply := false

_release_restrictions_apply if {
	lib.rule_data("pipeline_intention") == "release"
}

# Used by allowed_registries
_image_registry_allowed(image_repo, allowed_prefixes) if {
	some allowed_prefix in allowed_prefixes
	startswith(image_repo, allowed_prefix)
}
