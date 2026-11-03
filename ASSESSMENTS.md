# Reusable Question Banks

`assessments/index.yaml` lists banks in teaching order. Each bank uses schema
version 1 and the contract in `schemas/question-bank.schema.json`. This is an
authoring format for future application integration, not an existing Astrona
quiz API. No YAML question file is registered as a Markdown reading.

Each section has a knowledge check (`sections/section-010/quiz.yaml`, `sections/section-020/quiz.yaml`) after the last module summary of the section, and `sections/final-domain-quiz.yaml` covers the whole domain. Banks hold original single-choice questions with exactly three options, scoped to concepts taught in the course. They remain draft for review.

## Fields And Rendering

- `id`: stable bank or question identity; preserve it when editing wording.
- `scope`: section or domain checkpoint.
- `placement`: relative reading path after which the checkpoint belongs.
- `learning_objective`: the measurable outcome checked by the question.
- `source_readings`: author traceability to the teaching; not learner navigation.
- `prompt`: learner-visible question text.
- `options`: stable option IDs, answer text and per-option feedback.
- `correct_option`: the ID of the single correct option.
- `explanation`: feedback reinforcing the supported answer.

The application should send only the question ID, prompt and option IDs/text to
the learner before submission. Keep `correct_option`, `explanation` and option
explanations on the server until feedback is permitted. Match answers by option
ID, not display position, so a later renderer can shuffle choices safely.

The banks contain answer keys and are public learning material, so this is not
a secure examination bank. Do not treat scores as an official CCA result.

## Hands-On Coverage

This course has 4 ungraded playgrounds (one per module), 4 module labs and 2 capstone labs. Each task, launch entry and solution follows the reading part it practises. Every lab and playground passed static checks only (`astrona validate`, `bash -n`, YAML parsing). None was booted or run, so all labs are untested and live verification is pending.

| Module | Lab | Level |
| --- | --- | --- |
| 010/01 | Limit Egress To One External Partner | intermediate |
| 010/02 | Give shuttle A Fixed Source Address | intermediate |
| 010 | Capstone: A Restricted Partner Connection With A Fixed Source Address | advanced |
| 020/01 | Peer The Worker Nodes With The External Router | intermediate |
| 020/02 | Advertise The probe Service And The Pod Prefixes | intermediate |
| 020 | Capstone: Publish The probe Service To The External Router | advanced |
