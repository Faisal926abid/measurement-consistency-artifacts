import type { ValidationAcceptor, ValidationChecks, AstNode } from "langium";
import type {
  ReqAstType,
  Requirement,
  MeasurementDefinition,
  Model,
  Actor,
  Stakeholder,
  Quantifier,
  Unit,
  RelevantStakeholders as RelevantStakeholdersNode,
  Time,
  Beneficiary,
  Trigger,
  PreconditionStructure,
} from "./generated/ast.js";
import type { ReqServices } from "./req-module.js";

/**
 * Register custom validation checks.
 */
export function registerValidationChecks(services: ReqServices) {
  const registry = services.validation.ValidationRegistry;
  const validator = services.validation.ReqValidator;
  const checks: ValidationChecks<ReqAstType> = {
    // Model-level validations
    Model: [
      validator.checkUniqueActorNames,
      validator.checkUniqueStakeholderNames,
      validator.checkUniqueQuantifierNames,
      validator.checkUniqueUnitNames,
    ],
    // Requirement-level validations
    Requirement: [
      validator.checkRequirement,
      validator.checkIfParticipatingStakeholdersAreDefined,
    ],
    // RequirementContent: [
    //   // validator.checkRequirementContentHasActor,
    // ],
    RelevantStakeholders: [
      validator.checkRelevantStakeholdersNotEmpty,
    ],
    Time: [validator.checkTimeAmountIsPositive, validator.checkTimeUnitDefined],
    MeasurementDefinition: [validator.checkMeasurementDefinition],
    Beneficiary: [validator.checkBeneficiaryActorsDefined],
    Trigger: [validator.checkTriggerHasAction],
    // PreconditionStructure: [validator.checkPreconditionNonEmpty],
  };
  registry.register(checks, validator);
}

/**
 * Implementation of custom validations.
 */
export class ReqValidator {
  // TODO: Add logic here for validation checks of properties
  // See doc : https://langium.org/docs/learn/workflow/create_validations/
  /*
    checkElement(element: Element, accept: ValidationAcceptor): void {
        // Always accepts
    }
    */

  checkMeasurementDefinition(m: MeasurementDefinition, accept: ValidationAcceptor): void {
    if (m.minimum > m.maximum) {
      accept("error", "Measurement scale minimum exceeds maximum.", { node: m, property: "minimum" });
    }
    if (m.threshold < m.minimum || m.threshold > m.maximum) {
      accept("error", "Measurement threshold is outside the declared scale range.", { node: m, property: "threshold" });
    }
    if (!m.method) {
      accept("warning", "Measurement observation method is unspecified.", { node: m });
    }
    if (!m.evidence) {
      accept("warning", "Measurement verification evidence is unspecified.", { node: m });
    }
  }

  checkRequirement(requirement: Requirement, accept: ValidationAcceptor): void {
    // Structured conditions are checked against measurement metadata without English-text matching.
    // Only the simple, single-condition form is checked in this first prototype.
    const pre = requirement.earsPreStatement;
    const conditions: unknown[] = [];
    const walk = (node: unknown): void => {
      if (!node || typeof node !== 'object') return;
      const obj = node as Record<string, unknown>;
      if (typeof obj.scale === 'string' && typeof obj.threshold === 'number' && typeof obj.operator === 'string') {
        conditions.push(obj);
      }
      for (const key of ['preconditions', 'expression', 'condition', 'left', 'right']) {
        if (obj[key] && typeof obj[key] === 'object') walk(obj[key]);
      }
    };
    walk(pre);
    for (const entry of conditions) {
      const c = entry as {scale: string; operator: string; threshold: number};
      const m = requirement.measurement;
      if (!m) {
        accept('warning', `Structured measurement ${c.scale} has no measurement definition.`, {node: requirement});
      } else {
        if (c.scale !== m.scale) accept('error', `Measurement scale mismatch: condition ${c.scale}, definition ${m.scale}.`, {node: requirement});
        if (c.operator !== m.operator) accept('error', `Measurement operator mismatch: condition ${c.operator}, definition ${m.operator}.`, {node: requirement});
        if (c.threshold !== m.threshold) accept('error', `Measurement threshold mismatch: condition ${c.threshold}, definition ${m.threshold}.`, {node: requirement});
      }
    }
    // Narrow diagnostic for a KSS threshold explicitly stated in the free-text condition.
    // This is NOT a general semantic equivalence checker.
    if (requirement.measurement?.scale?.toUpperCase() === 'KSS') {
      const text = (requirement.$cstNode?.text ?? '').split('Measurement:')[0];
      const mentions = [
        ...text.matchAll(/\bKSS\s*(?:level\s*)?(\d+)\b/gi),
        ...text.matchAll(/\blevel\s*(\d+)\s+on\s+the\s+Karolinska\s+Sleepiness\s+Scale\b/gi)
      ].map(m => Number(m[1]));
      const distinct = [...new Set(mentions)];
      if (distinct.length === 1 && distinct[0] !== requirement.measurement.threshold) {
        accept('warning', `KSS threshold mismatch: condition states ${distinct[0]} but measurement metadata states ${requirement.measurement.threshold}.`, {node: requirement, property: 'measurement'});
      }
    }
    // Check that requirementID is unique within the model
    const model = requirement.$container;
    if (model && Array.isArray(model.requirements)) {
      const id = requirement.requirementID;
      if (id) {
        const duplicates = model.requirements.filter(
          (r) => r !== requirement && r.requirementID === id
        );
        if (duplicates.length > 0) {
          accept("error", `Requirement ID '${id}' is not unique. Choose a unique ID for each requirement.`, {
            node: requirement,
            property: "requirementID",
          });
        }
      }
    }
  }

  // checkRequirementContentHasActor(
  //   content: RequirementContent,
  //   accept: ValidationAcceptor
  // ): void {
  //   if (!content.actor) {
  //     accept("error", "Requirement must reference an actor.", {
  //       node: content,
  //       property: "actor",
  //     });
  //   }
  // }

  // no explicit modal verb property exists on RequirementContent in the current AST

  checkIfParticipatingStakeholdersAreDefined(
    requirement: Requirement,
    accept: ValidationAcceptor
  ): void {
    if (requirement.relevantStakeholders) {
      const stakeholders = requirement.relevantStakeholders.stakeholders;
      if (stakeholders.length === 0) {
        accept("error", "Relevant stakeholders are not defined.", {
          node: requirement,
          property: "relevantStakeholders",
        });
      }
    } else {
      accept("error", "Relevant stakeholders are not defined. Define them using the 'Relevant-Stakeholders:' keyword.", {
        node: requirement,
        property: "relevantStakeholders",
      });
    }
  }

  checkRelevantStakeholdersNotEmpty(
    node: RelevantStakeholdersNode,
    accept: ValidationAcceptor
  ): void {
    if (!node.stakeholders || node.stakeholders.length === 0) {
      accept("error", "Relevant-Stakeholders must list at least one stakeholder.", {
        node,
        property: "stakeholders",
      });
    }
  }

  checkUniqueActorNames(model: Model, accept: ValidationAcceptor): void {
    this.checkUniqueNames(model.actors ?? [], (a) => a.name, "Actor", accept);
  }

  checkUniqueStakeholderNames(
    model: Model,
    accept: ValidationAcceptor
  ): void {
    this.checkUniqueNames(
      model.stakeholders ?? [],
      (s) => s.name,
      "Stakeholder",
      accept
    );
  }

  checkUniqueQuantifierNames(
    model: Model,
    accept: ValidationAcceptor
  ): void {
    this.checkUniqueNames(
      model.quantifiers ?? [],
      (q) => q.name,
      "Quantifier",
      accept
    );
  }

  checkUniqueUnitNames(model: Model, accept: ValidationAcceptor): void {
    this.checkUniqueNames(model.units ?? [], (u) => u.name, "Unit", accept);
  }

  private checkUniqueNames<T extends Actor | Stakeholder | Quantifier | Unit>(
    nodes: T[],
    getName: (n: T) => string | undefined,
    label: string,
    accept: ValidationAcceptor
  ): void {
    const seen = new Map<string, T[]>();
    for (const n of nodes) {
      const name = getName(n);
      if (!name) continue;
      const arr = seen.get(name) ?? [];
      arr.push(n);
      seen.set(name, arr);
    }
    for (const [name, arr] of seen) {
      if (arr.length > 1) {
        arr.slice(1).forEach((d) =>
          accept("error", `${label} name '${name}' is not unique.`, {
            node: d as unknown as AstNode, // eslint-disable-line @typescript-eslint/no-explicit-any
            property: "name",
          })
        );
      }
    }
  }

  checkTimeAmountIsPositive(time: Time, accept: ValidationAcceptor): void {
    // amount is either STRING or INT; if INT, ensure > 0
    const anyAmount = (time as unknown as { amount?: unknown }).amount as
      | number
      | string
      | undefined;
    if (typeof anyAmount === "number" && anyAmount <= 0) {
      accept("error", "Time amount must be a positive integer.", {
        node: time,
        property: "amount",
      });
    }
  }

  checkTimeUnitDefined(time: Time, accept: ValidationAcceptor): void {
    if (!time.units) {
      accept("error", "Time must reference a defined Unit.", {
        node: time,
        property: "units",
      });
    }
  }

  checkBeneficiaryActorsDefined(
    beneficiary: Beneficiary,
    accept: ValidationAcceptor
  ): void {
    // Beneficiary may contain participantActor references; ensure all resolve
    (beneficiary.participantActor ?? []).forEach((a) => {
      if (!a) {
        accept("error", "Beneficiary references an undefined Actor.", {
          node: beneficiary,
        });
      }
    });
  }

  checkTriggerHasAction(trigger: Trigger, accept: ValidationAcceptor): void {
    if (!trigger.actions || !trigger.actions.name) {
      accept("error", "Trigger must define an action expression.", {
        node: trigger,
        property: "actions",
      });
    }
  }

  checkPreconditionNonEmpty(
    prec: PreconditionStructure,
    accept: ValidationAcceptor
  ): void {
    // For non-itemized, ensure expression exists; for itemized, ensure at least one condition
    const anyNode = prec as unknown as {
      expression?: unknown;
      precondition?: unknown[];
    };
    const hasExpression = Boolean(anyNode.expression);
    const hasItems = Array.isArray(anyNode.precondition)
      ? anyNode.precondition.length > 0
      : false;
    if (!hasExpression && !hasItems) {
      accept("error", "Preconditions must not be empty.", { node: prec });
    }
  }
}
