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

## 📦 Public API 公共API

### 🧬 Type Definitions 类型定义

#### pub struct ErrorData

Data structure used to describe error information.

描述错误信息的数据结构，包含以下字段：

- `err_type: String?`：

    optional error type

    可选的错误类型

- `err_msg: String`：

    error message

    错误消息

- `err_pos: Int`：

    start position of the error

    错误起始位置

- `err_offset: Int`：

    offset indicating the range of the error

    错误范围偏移量

#### enum Sequence[T]

Generic type representing a sequence, supporting two construction methods.

表示序列的通用类型，支持两种构造方式：

- `Arr(Array[T], String)`：

    Array-based sequence with a join string.

    数组形式的序列，带连接符。

- `Str(String)`：

    String-based sequence.

    字符串形式的序列。

---

### 🏗️ Constructor Functions 构造函数

- ErrorData:

    ```moonbit
    /// Creates an ErrorData instance
    /// 创建一个 ErrorData 实例
    fn ErrorData::make(
    err_type~ : String? = None,
    err_msg : String,
    err_pos~ : Int = -1,
    err_offset~ : Int = 0
    ) -> ErrorData
    ```

- Sequence:

    ```moonbit
    /// Construct a Sequence instance from array
    /// 从数组构造一个 Sequence
    pub fn[T : Show] Sequence::from_array(arr: Array[T], join~: String = " ") -> Sequence[T]

    /// Construct a Sequence instance from string
    /// 从字符串构造一个 Sequence
    pub fn Sequence::from_string(str: String) -> Sequence[Char]
    ```

---

### 🎯 主要功能函数

- ErrorData::mark

    ```moonbit
    /// Generate visual error markers to show error position, markers, and error messages
    /// 生成可视化错误标记，展示错误位置、标记和错误信息
    pub fn[T : Show] ErrorData::mark(
    self : ErrorData,
    seq : Sequence[T],
    marker~ : Char = '^',
    gen_msg~ : (String?, String) -> String = gen_err_msg
    ) -> String

    /// format error message into standard format: "Error(type): message"
    /// 格式化错误信息为标准格式："Error(type): message"
    fn gen_err_msg(err_type: String?, err_msg: String) -> String
    ```

    Users can format error messages into custom format by providing a custom function with same signature as `gen_err_msg`.

    用户可以通过提供与 `gen_err_msg` 具有相同函数签名的自定义函数，将错误信息格式化为自定义格式。

---

### 🧪 Usage Example 使用示例

- code:

    ```moonbit
    let data = ErrorData::make(
    err_type=Some("TypeError"),
    err_msg="Invalid token",
    err_pos=1,
    err_offset=0
    )

    let arr_seq = Sequence::from_array(["hello", "world"], " ")

    println(data.mark(arr_seq))
    ```

- output:

    ```txt
    hello world
          ^^^^^
    Error(TypeError): Invalid token
    ```
