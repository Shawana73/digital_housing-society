
import 'package:flutter/material.dart';
import '../../models/plot_model.dart';
import '../../theme/admin_theme.dart';

class PlotCard extends StatelessWidget {
final PlotModel plot;
final VoidCallback onEdit;
final VoidCallback onDelete;
final int index;

const PlotCard({
super.key,
required this.plot,
required this.onEdit,
required this.onDelete,
this.index = 0,
});

static const List<String> _plotImages = [
'assets/images/admin_realestate.png',
'assets/images/modern_apartment.png',
'assets/images/Green_Valley_Villa.png',
'assets/images/Royal Enclave.png',
'assets/images/Sunshine Residency.png',
'assets/images/admin_purple.png',
'assets/images/admin_villa.png',
'assets/images/housing_society.png',
];

String get _imagePath {
return _plotImages[
index % _plotImages.length];
}

Color _statusColor() {
switch (plot.status.toLowerCase()) {
case 'available':
return AdminColors.success;
case 'booked':
return AdminColors.warning;
case 'allocated':
return AdminColors.primary;
default:
return AdminColors.greyText;
}
}

@override
Widget build(BuildContext context) {
final statusColor = _statusColor();

return Container(
decoration: BoxDecoration(
color: AdminColors.white,
borderRadius: BorderRadius.circular(28),
border: Border.all(
color: AdminColors.border.withValues(
alpha: 0.8,
),
),
boxShadow: [
BoxShadow(
color: AdminColors.darkText.withValues(
alpha: 0.055,
),
blurRadius: 24,
offset: const Offset(0, 9),
),
],
),
clipBehavior: Clip.antiAlias,
child: Material(
color: Colors.transparent,
child: InkWell(
onTap: onEdit,
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
_buildImageHeader(statusColor),
Expanded(
child: Padding(
padding: const EdgeInsets.fromLTRB(
17,
14,
17,
15,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
_buildPlotTitle(),
const SizedBox(height: 8),
_buildPlotDetails(),
const Spacer(),
_buildPriceAndActions(),
],
),
),
),
],
),
),
),
);
}

Widget _buildImageHeader(Color statusColor) {
return SizedBox(
height: 150,
child: Stack(
fit: StackFit.expand,
children: [
Image.asset(
_imagePath,
fit: BoxFit.cover,
errorBuilder:
(context, error, stackTrace) {
return Container(
decoration:
const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
AdminColors.primary,
AdminColors.secondary,
],
),
),
child: const Icon(
Icons.home_work_rounded,
size: 55,
color: AdminColors.white,
),
);
},
),

DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.black.withValues(
alpha: 0.05,
),
Colors.black.withValues(
alpha: 0.12,
),
Colors.black.withValues(
alpha: 0.72,
),
],
),
),
),

Positioned(
top: 13,
left: 13,
child: Container(
padding:
const EdgeInsets.symmetric(
horizontal: 11,
vertical: 7,
),
decoration: BoxDecoration(
color: AdminColors.white.withValues(
alpha: 0.94,
),
borderRadius:
BorderRadius.circular(14),
),
child: Row(
mainAxisSize:
MainAxisSize.min,
children: [
Container(
width: 7,
height: 7,
decoration: BoxDecoration(
color: statusColor,
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
Text(
plot.status,
style: TextStyle(
color: statusColor,
fontSize: 10,
fontWeight: FontWeight.w900,
),
),
],
),
),
),

  Positioned(
    left: 16,
    right: 16,
    bottom: 13,
    child: Text(
      plot.plotId,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AdminColors.white,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.7,
      ),
    ),
  ),
],
),
);
}

Widget _buildPlotTitle() {
return Row(
children: [
Container(
height: 34,
width: 34,
decoration: BoxDecoration(
color: AdminColors.primary.withValues(
alpha: 0.09,
),
borderRadius:
BorderRadius.circular(11),
),
child: const Icon(
Icons.straighten_rounded,
color: AdminColors.primary,
size: 18,
),
),
const SizedBox(width: 9),
Expanded(
child: Text(
plot.plotSize,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AdminColors.darkText,
fontSize: 14,
fontWeight: FontWeight.w900,
),
),
),
],
);
}

Widget _buildPlotDetails() {
return Column(
children: [
_infoRow(
icon: Icons.location_on_outlined,
text: plot.location,
),
const SizedBox(height: 8),
_infoRow(
icon: Icons.notes_rounded,
text: plot.description.isEmpty
? 'No description available'
    : plot.description,
),
],
);
}

Widget _infoRow({
required IconData icon,
required String text,
}) {
return Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Icon(
icon,
color: AdminColors.greyText,
size: 16,
),
const SizedBox(width: 7),
Expanded(
child: Text(
text,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AdminColors.greyText,
fontSize: 11.5,
fontWeight: FontWeight.w600,
height: 1.3,
),
),
),
],
);
}

Widget _buildPriceAndActions() {
return Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Container(
width: double.infinity,
padding:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 9,
),
decoration: BoxDecoration(
color: AdminColors.primary.withValues(
alpha: 0.055,
),
borderRadius:
BorderRadius.circular(14),
),
child: Row(
children: [
const Icon(
Icons.payments_outlined,
color: AdminColors.primary,
size: 18,
),
const SizedBox(width: 7),
const Text(
'Price',
style: TextStyle(
color: AdminColors.greyText,
fontSize: 10,
fontWeight: FontWeight.w700,
),
),
const Spacer(),
Flexible(
child: Text(
'PKR ${plot.price.toStringAsFixed(0)}',
maxLines: 1,
overflow:
TextOverflow.ellipsis,
textAlign: TextAlign.end,
style: const TextStyle(
color: AdminColors.primary,
fontSize: 15,
fontWeight: FontWeight.w900,
),
),
),
],
),
),

const SizedBox(height: 10),

Row(
children: [
Expanded(
child: SizedBox(
height: 42,
  child: ElevatedButton.icon(
    onPressed: onEdit,
    icon: const Icon(
      Icons.edit_rounded,
      size: 16,
    ),
    label: const Text(
      'Edit',
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: AdminColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
    ),
  ),
),
),
const SizedBox(width: 8),
SizedBox(
  height: 42,
  width: 44,
  child: IconButton(
  onPressed: onDelete,
  tooltip: 'Delete plot',
  style: IconButton.styleFrom(
  backgroundColor:
  AdminColors.rejected
      .withValues(alpha: 0.09),
  shape:
  RoundedRectangleBorder(
  borderRadius:
  BorderRadius.circular(14),
  ),
  ),
  icon: Icon(
  Icons.delete_rounded,
  size: 19,
  color: AdminColors.rejected,
  ),
  ),
  ),
],
),
],
);
}
}

