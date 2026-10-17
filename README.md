# dart-vm-survey

Investigation notes and reproductions for
[dart-lang/sdk#64620](https://github.com/dart-lang/sdk/issues/64620):
a failing `as FutureOr<T>` cast on a Smi crashes the Dart VM.

- `repro/` — minimal reproductions (see `repro/README.md`)
- `repro-large/` — larger variants
- `try1/` — early exploration
- `evidence/` — logs, disassembly, gdb output, version matrices
- `findings-ja.md`, `report-draft.md` — findings (Japanese / draft)
- `issue-draft-*.md`, `flutter-162375-comment-en.md` — drafts of the filed issue and a related flutter/flutter#162375 comment
