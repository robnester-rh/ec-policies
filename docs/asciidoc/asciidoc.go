// Copyright The Enterprise Contract Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

package asciidoc

import (
	_ "embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"text/template"

	"github.com/open-policy-agent/opa/ast"
	"github.com/open-policy-agent/opa/ast/json"
)

type doc struct {
	Name        string
	Qualifier   string
	Description string
	Packages    *[]pkg
	Collections *[]col
}

func (d *doc) SetAnnotations(a []ast.FlatAnnotationsRefSet) {
	packages := make([]pkg, 0, 5)
	collections := make([]col, 0, 5)
	for _, set := range a {
		rules := make([]*ast.Annotations, 0, 5)
		for _, ref := range set {
			pkgPath := ref.GetPackage().Path.String()
			locationPrefix := filepath.Join("policy", d.Qualifier)
			if strings.HasPrefix(ref.Location.File, locationPrefix) {
				if strings.Contains(pkgPath, ".collection.") {
					c := col{ref.Annotations, nil}
					c.SetAnnotations(a)
					collections = append(collections, c)
				} else {
					switch ref.Annotations.Scope {
					case "package":
						packages = append(packages, pkg{ref.Annotations, &rules})
					case "rule":
						rules = append(rules, ref.Annotations)
					}
				}
			}
		}

		sort.Slice(rules, func(i, j int) bool {
			return rules[i].Title < rules[j].Title
		})
	}

	if len(packages) > 0 {
		sort.Slice(packages, func(i, j int) bool {
			return packages[i].Annotations.Title < packages[j].Annotations.Title
		})
		d.Packages = &packages
	}

	if len(collections) > 0 {
		sort.Slice(collections, func(i, j int) bool {
			return collections[i].Annotations.Title < collections[j].Annotations.Title
		})
		d.Collections = &collections
	}
}

func (d doc) generateNav(module string) error {
	navpath := filepath.Join(module, "partials", d.Qualifier+"_policy_nav.adoc")
	nav, err := os.Create(navpath)
	if err != nil {
		return fmt.Errorf("creating file %q: %w", navpath, err)
	}
	defer nav.Close()

	return navTemplate.Execute(nav, d)
}

func (d doc) generatePolicy(module string) error {
	navpath := filepath.Join(module, "pages", d.Qualifier+"_policy.adoc")
	nav, err := os.Create(navpath)
	if err != nil {
		return fmt.Errorf("creating file %q: %w", navpath, err)
	}
	defer nav.Close()

	return policyTemplate.Execute(nav, d)
}

type col struct {
	*ast.Annotations
	Rules *[]*ast.Annotations
}

func (c *col) SetAnnotations(a []ast.FlatAnnotationsRefSet) {
	rules := make([]*ast.Annotations, 0, 5)
	packageTitles := map[string]string{}
	title := c.Annotations.Title
	for _, set := range a {
		for _, ref := range set {
			a := ref.Annotations
			if a.Scope == "package" {
				packageTitles[ref.Path.String()] = a.Title
			}
			if cs, ok := ref.Annotations.Custom["collections"].([]any); ok {
				for _, collection := range cs {
					a.Custom["package_title"] = packageTitles[ref.GetPackage().Path.String()]
					if collection == title {
						rules = append(rules, a)
					}
				}
			}
		}
	}

	sort.Slice(rules, func(i, j int) bool {
		return rules[i].Custom["package_title"].(string)+rules[i].Title < rules[j].Custom["package_title"].(string)+rules[j].Title
	})

	c.Rules = &rules
}

type pkg struct {
	*ast.Annotations
	Rules *[]*ast.Annotations
}

func (p *pkg) path() []string {
	target := p.GetTargetPath()
	path := make([]string, 0, len(target))

	for _, p := range target {
		v := strings.TrimSuffix(strings.TrimPrefix(p.String(), `"`), `"`)

		path = append(path, v)
	}

	return path
}

var docs = []doc{
	{
		Name:        "Release",
		Qualifier:   "release",
		Description: "These rules are applied to pipeline run attestations associated with container images built by Konflux.",
	},
	{
		Name:        "Pipeline",
		Qualifier:   "pipeline",
		Description: "These rules are applied to Tekton pipeline definitions.",
	},
	{
		Name:        "Task",
		Qualifier:   "task",
		Description: "These rules are applied to Tekton task definitions.",
	},
	{
		Name:        "Build Task",
		Qualifier:   "build_task",
		Description: "These rules are applied to Tekton build task definitions.",
	},
	{
		Name:        "StepAction",
		Qualifier:   "stepaction",
		Description: "These rules are applied to Tekton StepAction definitions.",
	},
}

//go:embed nav.template
var navTemplateText string

//go:embed policy.template
var policyTemplateText string

var navTemplate *template.Template

var policyTemplate *template.Template

func init() {
	funcs := template.FuncMap{
		"anchor":           anchor,
		"packageName":      packageName,
		"warningOrFailure": warningOrFailure,
		"toUpper":          strings.ToUpper,
		"toTitle":          strings.ToTitle,
		"isBuiltIn":        isBuiltIn,
	}

	navTemplate = template.Must(template.New("nav").Funcs(funcs).Parse(navTemplateText))

	policyTemplate = template.Must(template.New("policy").Funcs(funcs).Parse(policyTemplateText))
}

func packageName(p *pkg) string {
	path := p.path()
	return path[len(path)-1]
}

func anchor(a *ast.Annotations) string {
	path := a.GetTargetPath()
	switch a.Scope {
	case "package":
		significant := path[len(path)-1]
		pkg, err := strconv.Unquote(significant.String())
		if err != nil {
			panic(err)
		}
		return pkg + "_package"
	case "rule":
		significant := path[len(path)-2]
		pkg, err := strconv.Unquote(significant.String())
		if err != nil {
			panic(err)
		}
		return pkg + "__" + a.Custom["short_name"].(string)
	}

	panic("expecting to be called for package or rules, was called for: " + a.Scope)
}

func warningOrFailure(a *ast.Annotations) string {
	path := a.GetTargetPath().String()

	if strings.HasSuffix(path, ".deny") {
		return "failure"
	}

	if strings.HasSuffix(path, ".warn") {
		return "warning"
	}

	panic(fmt.Sprintf("can't reduce to warning or failure rule with the path: %q", path))
}

func isBuiltIn(a *ast.Annotations) bool {
	if cs, ok := a.Custom["collections"].([]any); ok {
		for _, c := range cs {
			if c == "builtin" {
				return true
			}
		}
	}

	return false
}

func inspect(rego []string) ([]ast.FlatAnnotationsRefSet, error) {
	options := ast.ParserOptions{
		ProcessAnnotation: true,
		JSONOptions: &json.Options{
			MarshalOptions: json.MarshalOptions{
				IncludeLocation: json.NodeToggle{
					AnnotationsRef: true,
				},
			},
		},
	}

	annotations := make([]ast.FlatAnnotationsRefSet, 0, 50)

	for _, r := range rego {
		fileSystem := os.DirFS(r)
		fs.WalkDir(fileSystem, ".", func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}

			if !strings.HasSuffix(path, ".rego") || strings.HasSuffix(path, "_test.rego") {
				return nil
			}

			data, err := fs.ReadFile(fileSystem, path)
			if err != nil {
				return err
			}

			mod, err := ast.ParseModuleWithOpts(path, string(data), options)
			if err != nil {
				return err
			}

			as, x := ast.BuildAnnotationSet([]*ast.Module{mod})
			if len(x) > 0 {
				return err
			}

			ann := as.Flatten()

			if len(ann) > 0 {
				annotations = append(annotations, ann)
			}

			return nil
		})
	}

	return annotations, nil
}

func GenerateAsciidoc(module string, rego ...string) error {
	annotations, err := inspect(rego)
	if err != nil {
		return err
	}

	for _, d := range docs {
		d.SetAnnotations(annotations)
		if err := d.generateNav(module); err != nil {
			return err
		}
		if err := d.generatePolicy(module); err != nil {
			return err
		}
	}

	return nil
}
