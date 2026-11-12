# KCN-judu/err_marker

## 📝 Introduction 介绍

This is a visualizing tool that locates the source of errors within sequences and outputs formatted results, designed to assist users and developers in quickly identifying input that triggers errors.

这是一个用于在序列中定位错误来源的可视化工具，并输出格式化结果，旨在帮助用户和开发者快速识别引发错误的输入内容。

## 📖 Manual 手册

The manual (API, tutorial and design, in English, 简体中文 and 日本語) is in
[`doc/manual`](doc/manual/index.md); translations live in `doc/locale`. The
roadmap to 0.2.0 is tracked in
[#5](https://github.com/moonbit-community/err_marker/issues/5).

手册（API、教程、设计；英文、简体中文、日本語）位于
[`doc/manual`](doc/manual/index.md)，译文在 `doc/locale`。0.2.0 的路线图见
[#5](https://github.com/moonbit-community/err_marker/issues/5)。

## 🧪 Usage 用法

```bash
moon add KCN-judu/err_marker@0.2.0
```

```moonbit nocheck
let report = @err_marker.Report::new(Error, "unknown mode 'sovle'")
  .with_code("E01")
  .with_mark(
    @err_marker.Mark::primary(
      @err_marker.Span::new(3, 4),
      message="did you mean 'solve'?",
    ),
  )
let args = @err_marker.Sequence::from_args(["sudoku", "export", "a.txt", "sovle", "out.txt"])
println(report.render(args))
```

```text
sudoku export a.txt sovle out.txt
                    ^^^^^ did you mean 'solve'?
error[E01]: unknown mode 'sovle'
```

- Positions are element indices for arguments and arrays, and character
  indices for strings. Columns follow Unicode 18.0.0, so CJK text and emoji
  line up. 位置对参数和数组是元素下标，对字符串是字符下标；列宽遵循 Unicode
  18.0.0，中日韩文字和 emoji 都能对齐。
- Several marks (`^` primary, `-` secondary), messages, notes, codes,
  severities and optional ANSI colour. 支持多处标记、说明、附注、错误码、严重级别和可选的 ANSI 颜色。
- `KCN-judu/err_marker/cursor`: terminal column arithmetic. 终端列宽计算。
- `KCN-judu/err_marker/error_report`: conversion to
  `marianoguerra/error-report`. 转换为 error-report 的报告。
- `ErrorData::mark` (0.1) is deprecated; see "Migrating from 0.1" in the
  tutorial. `ErrorData::mark`（0.1）已弃用，迁移方法见教程中的
  "Migrating from 0.1"。

## 📄 License 许可证

Apache-2.0.
