package lib.tekton

import rego.v1

import data.lib.json as j
import data.lib.time as time_lib

# regal ignore:prefer-package-imports
import data.lib.rule_data as lib_rule_data

# Returns a subset of tasks that use unpinned Task references.
unpinned_task_references(tasks) := {task |
	some task in tasks
	not task_ref(task).pinned
}

# Returns if the list of trusted Tasks are missing
default missing_trusted_tasks_data := false

missing_trusted_tasks_data if {
	count(_trusted_tasks) == 0
}

default task_expiry_warnings_after := 0

task_expiry_warnings_after := grace if {
	grace_period_days := lib_rule_data("task_expiry_warning_days")
	grace_period_days > 0
	grace := time.add_date(
		time_lib.effective_current_time_ns, 0, 0,
		grace_period_days,
	)
}

# Returns the epoch time in nanoseconds of the time when the Task expires, or
# nothing if Task is not set to expire currently.
expiry_of(task) := expires if {
	expires := _task_expires_on(task)

	# only report if the task is expiring within task_expiry_warning_days days
	expires > task_expiry_warnings_after
}

# Returns a subset of tasks that do not use a trusted Task reference.
untrusted_task_refs(tasks) := {task |
	some task in tasks
	not is_trusted_task(task)
}

# Returns true if the task uses a trusted Task reference.
is_trusted_task(task) if {
	ref := task_ref(task)
	records := _trusted_tasks[ref.key]

	some record in records

	# A trusted task reference is one that is recorded in the trusted tasks data, this is done by
	# matching its pinned reference; note no care is given to the expiry or freshness since expired
	# records have already been filtered out.
	record.ref == ref.pinned_ref
}

# Returns the date in epoch nanoseconds when the task expires, or nothing if it
# hasn't expired yet.
_task_expires_on(task) := expires if {
	ref := task_ref(task)
	records := _trusted_tasks[ref.key]

	some record in records
	record.ref == ref.pinned_ref

	expires = time.parse_rfc3339_ns(record.expires_on)
}

# _trusted_tasks provides a safe way to access the list of trusted tasks. It prevents a policy rule
# from incorrectly not evaluating due to missing data. It also removes stale records.
_trusted_tasks[key] := pruned_records if {
	some key, records in _trusted_tasks_data
	pruned_records := time_lib.acceptable_items(records)
}

# Merging in the trusted_tasks rule data makes it easier for users to customize their trusted tasks
_trusted_tasks_data := object.union(data.trusted_tasks, lib_rule_data("trusted_tasks"))

data_errors contains error if {
	some e in j.validate_schema(
		_trusted_tasks_data,
		{
			"$schema": "http://json-schema.org/draft-07/schema#",
			"type": "object",
			"patternProperties": {".*": {
				"type": "array",
				"items": {
					"type": "object",
					"properties": {
						"effective_on": {"type": "string"},
						"expires_on": {"type": "string"},
						"ref": {"type": "string"},
					},
					"required": ["effective_on", "ref"],
					"additionalProperties": false,
				},
				"minItems": 1,
			}},
		},
	)

	error := {
		"message": sprintf("trusted_tasks data has unexpected format: %s", [e.message]),
		"severity": e.severity,
	}
}

data_errors contains error if {
	some task, refs in _trusted_tasks_data
	some i, ref in refs
	not time.parse_rfc3339_ns(ref.effective_on)
	error := {
		"message": sprintf(
			"trusted_tasks.%s[%d].effective_on is not valid RFC3339 format: %q",
			[task, i, ref.effective_on],
		),
		"severity": "failure",
	}
}

data_errors contains error if {
	some task, refs in _trusted_tasks_data
	some i, ref in refs
	not time.parse_rfc3339_ns(ref.expires_on)
	error := {
		"message": sprintf(
			"trusted_tasks.%s[%d].expires_on is not valid RFC3339 format: %q",
			[task, i, ref.expires_on],
		),
		"severity": "failure",
	}
}

data_errors contains error if {
	some error in j.validate_schema(
		{"task_expiry_warning_days": lib_rule_data("task_expiry_warning_days")},
		{
			"$schema": "http://json-schema.org/draft-07/schema#",
			"type": "object",
			"properties": {"task_expiry_warning_days": {
				"type": "integer",
				"minimum": 0,
			}},
		},
	)
}
