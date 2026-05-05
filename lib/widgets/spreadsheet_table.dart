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

  const CellData({
    this.value = '',
    this.hint = '',
    this.textColor,
  });
}

/// Generic spreadsheet table with frozen first column and sticky header.
class SpreadsheetTable extends StatefulWidget {
  final List<SpreadsheetColumn> columns;
  final int rowCount;
  final CellData Function(int row, int col) cellBuilder;
  final void Function(int row, int col, String value) onCellChanged;
  final VoidCallback onAddRow;
  final void Function(int row)? onDeleteRow;
  final bool canDeleteRows;
  final double frozenColumnWidth;
  final double rowHeight;

  const SpreadsheetTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    required this.onCellChanged,
    required this.onAddRow,
    this.onDeleteRow,
    this.canDeleteRows = true,
    this.frozenColumnWidth = 130,
    this.rowHeight = 46,
  });

  @override
  State<SpreadsheetTable> createState() => _SpreadsheetTableState();
}

class _SpreadsheetTableState extends State<SpreadsheetTable> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _headerHorizontalScrollController = ScrollController();

  // Track which cell is focused for highlight
  int? _focusedRow;
  int? _focusedCol;

  @override
  void initState() {
    super.initState();
    // Sync horizontal scroll between header and body
    _horizontalScrollController.addListener(_syncHeaderScroll);
  }

  void _syncHeaderScroll() {
    if (_headerHorizontalScrollController.hasClients) {
      _headerHorizontalScrollController
          .jumpTo(_horizontalScrollController.offset);
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_syncHeaderScroll);
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _headerHorizontalScrollController.dispose();
    super.dispose();
  }

  // Columns after the frozen first column
  List<SpreadsheetColumn> get _scrollableColumns =>
      widget.columns.length > 1 ? widget.columns.sublist(1) : [];


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sticky Header
          _buildHeaderRow(colorScheme, borderColor),

          // Data Rows
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: widget.rowCount * widget.rowHeight +
                  widget.rowHeight, // +1 for add button row
            ),
            child: ListView.builder(
              controller: _verticalScrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.rowCount + 1, // +1 for "Add Row" button
              itemBuilder: (context, index) {
                if (index == widget.rowCount) {
                  return _buildAddRowButton(colorScheme, borderColor);
                }
                return _buildDataRow(index, colorScheme, borderColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(ColorScheme colorScheme, Color borderColor) {
    return Container(
      height: widget.rowHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Frozen header cell
          _buildHeaderCell(
            widget.columns.first.header,
            widget.frozenColumnWidth,
            colorScheme,
            borderColor,
            isFirst: true,
          ),

          // Scrollable header cells
          Expanded(
            child: IgnorePointer(
              child: SingleChildScrollView(
                controller: _headerHorizontalScrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (int i = 0; i < _scrollableColumns.length; i++)
                      _buildHeaderCell(
                        _scrollableColumns[i].header,
                        _scrollableColumns[i].width,
                        colorScheme,
                        borderColor,
                        isCalculated: _scrollableColumns[i].isCalculated,
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
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Frozen first column cell
          _buildCell(row, 0, widget.columns.first, widget.frozenColumnWidth,
              colorScheme, borderColor),

          // Scrollable data cells
          Expanded(
            child: SingleChildScrollView(
              controller:
                  row == 0 ? _horizontalScrollController : null,
              scrollDirection: Axis.horizontal,
              physics: row == 0
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  for (int col = 1; col < widget.columns.length; col++)
                    _buildCell(row, col, widget.columns[col],
                        widget.columns[col].width, colorScheme, borderColor),
                  if (widget.canDeleteRows)
                    _buildDeleteButton(row, colorScheme),
                ],
              ),
            ),
          ),
        ],
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
      child: Text(
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
    return InkWell(
      onTap: widget.onAddRow,
      child: Container(
        height: widget.rowHeight,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.08),
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
  }
}
