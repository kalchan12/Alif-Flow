import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configuration for a single column in the spreadsheet.
class SpreadsheetColumn {
  final String header;
  final double width;
  final bool isCalculated;
  final bool isNumeric;
  final bool isReadOnly;
  final bool isProductName;

  const SpreadsheetColumn({
    required this.header,
    this.width = 90,
    this.isCalculated = false,
    this.isNumeric = false,
    this.isReadOnly = false,
    this.isProductName = false,
  });
}

/// A single cell value with optional styling hint.
class CellData {
  final String value;
  final String hint;
  final Color? textColor;
  final String? subtitle;

  const CellData({
    this.value = '',
    this.hint = '',
    this.textColor,
    this.subtitle,
  });
}

/// Generic spreadsheet table with frozen first column and sticky header.
class SpreadsheetTable extends StatefulWidget {
  final List<SpreadsheetColumn> columns;
  final int rowCount;
  final CellData Function(int row, int col) cellBuilder;
  final CellData Function(int col)? footerBuilder;
  final void Function(int row, int col, String value) onCellChanged;
  final VoidCallback onAddRow;
  final VoidCallback? onUpdateLocally;
  final void Function(int row)? onDeleteRow;
  final bool canDeleteRows;
  final double rowHeight;

  const SpreadsheetTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    this.footerBuilder,
    required this.onCellChanged,
    required this.onAddRow,
    this.onUpdateLocally,
    this.onDeleteRow,
    this.canDeleteRows = true,
    this.rowHeight = 46,
  });

  @override
  State<SpreadsheetTable> createState() => _SpreadsheetTableState();
}

class _SpreadsheetTableState extends State<SpreadsheetTable> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // Track which cell is focused for highlight
  int? _focusedRow;
  int? _focusedCol;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.2);

    final int listCount = widget.rowCount + 1 + (widget.footerBuilder != null ? 1 : 0);
    final double totalWidth = widget.columns.fold(0.0, (sum, col) => sum + col.width) + (widget.canDeleteRows ? 44.0 : 0.0);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sticky Header
              _buildHeaderRow(colorScheme, borderColor),

              // Data Rows
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: listCount * widget.rowHeight,
                ),
                child: ListView.builder(
                  controller: _verticalScrollController,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: listCount,
                  itemBuilder: (context, index) {
                    if (index < widget.rowCount) {
                      return _buildDataRow(index, colorScheme, borderColor);
                    } else if (index == widget.rowCount) {
                      return _buildAddRowButton(colorScheme, borderColor);
                    } else {
                      return _buildFooterRow(colorScheme, borderColor);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(ColorScheme colorScheme, Color borderColor) {
    return Container(
      height: widget.rowHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
        ),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.columns.length; i++)
            _buildHeaderCell(
              widget.columns[i].header,
              widget.columns[i].width,
              colorScheme,
              borderColor,
              isFirst: i == 0,
            ),
          if (widget.canDeleteRows)
            SizedBox(
              width: 44,
              child: Center(
                child: Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String text,
    double width,
    ColorScheme colorScheme,
    Color borderColor, {
    bool isFirst = false,
    bool isCalculated = false,
  }) {
    return Container(
      width: width,
      height: widget.rowHeight,
      decoration: BoxDecoration(
        color: isCalculated
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.15)
            : null,
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: isFirst ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildDataRow(int row, ColorScheme colorScheme, Color borderColor) {
    final isEvenRow = row % 2 == 0;

    return Container(
      height: widget.rowHeight,
      decoration: BoxDecoration(
        color: isEvenRow
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          for (int col = 0; col < widget.columns.length; col++)
            _buildCell(row, col, widget.columns[col], widget.columns[col].width,
                colorScheme, borderColor),
          if (widget.canDeleteRows) _buildDeleteButton(row, colorScheme),
        ],
      ),
    );
  }

  Widget _buildFooterRow(ColorScheme colorScheme, Color borderColor) {
    return Container(
      height: widget.rowHeight,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        border: Border(top: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          for (int col = 0; col < widget.columns.length; col++)
            _buildFooterCell(col, widget.columns[col], colorScheme, borderColor),
          if (widget.canDeleteRows)
            SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildFooterCell(
    int col,
    SpreadsheetColumn column,
    ColorScheme colorScheme,
    Color borderColor,
  ) {
    final cellData = widget.footerBuilder!(col);

    return Container(
      width: column.width,
      height: widget.rowHeight,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: column.isProductName ? Alignment.centerLeft : Alignment.center,
      child: Text(
        cellData.value.isNotEmpty ? cellData.value : cellData.hint,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: cellData.textColor ?? colorScheme.primary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCell(
    int row,
    int col,
    SpreadsheetColumn column,
    double width,
    ColorScheme colorScheme,
    Color borderColor,
  ) {
    final cellData = widget.cellBuilder(row, col);
    final isFocused = _focusedRow == row && _focusedCol == col;

    return Container(
      width: width,
      height: widget.rowHeight,
      decoration: BoxDecoration(
        color: column.isCalculated
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.1)
            : null,
        border: Border(
          right: BorderSide(color: borderColor),
          top: isFocused
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
          bottom: isFocused
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
          left: isFocused
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
      ),
      child: column.isReadOnly
          ? _buildReadOnlyCell(cellData, column, colorScheme)
          : _buildEditableCell(row, col, cellData, column, colorScheme),
    );
  }

  Widget _buildReadOnlyCell(
    CellData cellData,
    SpreadsheetColumn column,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: column.isProductName ? Alignment.centerLeft : Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: column.isProductName ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            cellData.value.isNotEmpty ? cellData.value : cellData.hint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: column.isCalculated ? FontWeight.w700 : FontWeight.w500,
              color: cellData.textColor ??
                  (cellData.value.isNotEmpty
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (cellData.subtitle != null && cellData.subtitle!.isNotEmpty)
            Text(
              cellData.subtitle!,
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
    int row,
    int col,
    CellData cellData,
    SpreadsheetColumn column,
    ColorScheme colorScheme,
  ) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          if (hasFocus) {
            _focusedRow = row;
            _focusedCol = col;
          } else if (_focusedRow == row && _focusedCol == col) {
            _focusedRow = null;
            _focusedCol = null;
          }
        });
      },
      child: TextFormField(
        initialValue: cellData.value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: column.isCalculated ? FontWeight.w700 : FontWeight.w400,
          color: cellData.textColor ?? colorScheme.onSurface,
        ),
        textAlign: column.isNumeric ? TextAlign.center : TextAlign.left,
        decoration: InputDecoration(
          hintText: cellData.hint,
          hintStyle: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          isDense: true,
        ),
        keyboardType: column.isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: column.isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
            : null,
        textInputAction: TextInputAction.next,
        onChanged: (value) => widget.onCellChanged(row, col, value),
      ),
    );
  }

  Widget _buildDeleteButton(int row, ColorScheme colorScheme) {
    return SizedBox(
      width: 44,
      height: widget.rowHeight,
      child: IconButton(
        icon: Icon(
          Icons.close_rounded,
          size: 16,
          color: colorScheme.error.withValues(alpha: 0.7),
        ),
        onPressed: widget.rowCount > 1
            ? () => widget.onDeleteRow?.call(row)
            : null,
        visualDensity: VisualDensity.compact,
        tooltip: 'Delete row',
      ),
    );
  }

  Widget _buildAddRowButton(ColorScheme colorScheme, Color borderColor) {
    Widget addRowContent = InkWell(
      onTap: widget.onAddRow,
      child: Container(
        height: widget.rowHeight,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Add Row',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onUpdateLocally == null) {
      return addRowContent;
    }

    return Row(
      children: [
        Expanded(child: addRowContent),
        Expanded(
          child: InkWell(
            onTap: widget.onUpdateLocally,
            child: Container(
              height: widget.rowHeight,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border(
                  bottom: BorderSide(color: borderColor),
                  left: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Save Draft',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
