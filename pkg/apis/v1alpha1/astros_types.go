package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:path=astros
// +kubebuilder:resource:shortName=astro
// +kubebuilder:printcolumn:name="Phase",type="string",JSONPath=".status.phase",description="The working phase of astro."
// +kubebuilder:printcolumn:name="NodeNumber",type="integer",JSONPath=".status.nodeNumber",description="The number of nodes in a directed acyclic graph."
// +kubebuilder:printcolumn:name="ReadyNodeNumber",type="integer",JSONPath=".status.readyNodeNumber",description="The number of ready nodes in a directed acyclic graph."

// Astro is a specification for a Astro resource
type Astro struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   AstroSpec   `json:"spec,omitempty"`
	Status AstroStatus `json:"status,omitempty"`
}

type AstroStarType string

const (
	AstroStarDocker AstroStarType = "docker"
)

type AstroStar struct {
	Name string        `json:"name"`
	Type AstroStarType `json:"type"`
	// +optional
	Dependencies []string `json:"dependencies,omitempty"`

	// docker type configuration

	// +optional
	Action string `json:"action,omitempty"`
	// +optional
	Target string `json:"target,omitempty"`
	// +optional
	Image string `json:"image,omitempty"`
	// +optional
	Port int32 `json:"port,omitempty"`
}

// AstroSpec is the spec for a Astro resource
type AstroSpec struct {
	Stars []AstroStar `json:"stars,omitempty"`
}

type AstroConditionType string

const (
	AstroConditionInitialized AstroConditionType = "Initialized"
	AstroConditionReady       AstroConditionType = "Ready"
	AstroConditionLaunched    AstroConditionType = "Launched"
	AstroConditionFailed      AstroConditionType = "Failed"
	AstroConditionSucceeded   AstroConditionType = "Succeeded"
)

// Condition defines an observation of a Cluster API resource operational state.
type AstroCondition struct {
	Type string `json:"type"`

	// Workflow status
	Status AstroConditionType `json:"status"`

	// Last time the condition transitioned from one status to another.
	// This should be when the underlying condition changed. If that is not known, then using the time when
	// the API field changed is acceptable.
	LastTransitionTime metav1.Time `json:"lastTransitionTime"`
}

type AstroRef struct {
	// +optional
	Name string `json:"name,omitempty"`
	// +optional
	Namespace string `json:"namespace,omitempty"`
}

// AstroStatus is the status for a Astro resource
type AstroStatus struct {
	// +optional
	WorkflowEngineInitialized bool `json:"workflowEngineInitialized,omitempty"`
	// +optional
	Conditions []AstroCondition `json:"conditions,omitempty"`
	// +optional
	Phase AstroConditionType `json:"phase,omitempty"`
	// +optional
	DeploymentRef []AstroRef `json:"deploymentRef,omitempty"`
	// +optional
	ServiceRef []AstroRef `json:"serviceRef,omitempty"`
	// +optional
	AstermuleRef AstroRef `json:"astermuleRef,omitempty"`
	// +optional
	NodeNumber int32 `json:"nodeNumber,omitempty"`
	// +optional
	ReadyNodeNumber int32 `json:"readyNodeNumber,omitempty"`
}

// +kubebuilder:object:root=true
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// AstroList is a list of Astro resources
type AstroList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`

	Items []Astro `json:"items"`
}
