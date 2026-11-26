# Spec Delta: <capability-path>

## Purpose

<!-- Obrigatório apenas ao introduzir uma nova capability (alimenta a spec principal no sync). -->
<!-- Para capabilities já existentes, o ## Purpose da spec principal é preservado intacto. -->

Descrição breve do propósito desta capability e do problema que ela resolve.

## ADDED Requirements

### Requirement: <Nome do novo requisito>
The system SHALL <comportamento obrigatório e verificável>.

#### Scenario: <Cenário principal>
- **GIVEN** <estado ou pré-condição inicial>
- **WHEN** <ação ou evento disparado>
- **THEN** <resultado observável esperado>

## MODIFIED Requirements

<!-- Inclua o requisito completo (texto + TODOS os cenários que permanecem válidos após a mudança, além dos novos/alterados). -->

### Requirement: <Nome do requisito existente>
The system MUST <comportamento atualizado>.

#### Scenario: <Cenário preservado>
- **GIVEN** <pré-condição>
- **WHEN** <evento>
- **THEN** <resultado preservado>

#### Scenario: <Cenário novo ou alterado>
- **GIVEN** <pré-condição>
- **WHEN** <evento>
- **THEN** <novo resultado>

## REMOVED Requirements

### Requirement: <Nome do requisito removido>

## RENAMED Requirements

- FROM: `### Requirement: <Nome antigo>`
- TO: `### Requirement: <Nome novo>`
