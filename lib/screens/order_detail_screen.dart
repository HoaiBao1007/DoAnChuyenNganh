// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_response.dart';
import '../utils/format.dart';
import '../utils/image_url_helper.dart';
import 'rating_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderResponse order;

  const OrderDetailScreen({super.key, required this.order});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  String _fullAddress(AddressResponse? addr) {
    if (addr == null) return '';
    final parts = [
      addr.addressLine1,
      if (addr.addressLine2 != null && addr.addressLine2!.isNotEmpty)
        addr.addressLine2!,
      addr.city,
      if (addr.postalCode != null && addr.postalCode!.isNotEmpty)
        addr.postalCode!,
      addr.country,
    ];
    return parts.where((e) => e.trim().isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final items = order.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${order.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin chung + tiền / voucher
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái: ${order.status}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày đặt: ${_formatDate(order.orderDate)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // Tiền hàng (totalAmount trước giảm)
                  Text(
                    'Tiền hàng: ${Format.currency(order.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),

                  // Voucher dùng (nếu có)
                  if (order.voucherCode != null &&
                      order.voucherCode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Voucher: ${order.voucherCode}',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],

                  // Số tiền giảm
                  const SizedBox(height: 4),
                  Text(
                    'Giảm giá: -${Format.currency(order.discountAmount)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),

                  // Thành tiền cuối cùng (finalAmount)
                  const SizedBox(height: 4),
                  Text(
                    'Thành tiền: ${Format.currency(order.finalAmount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Phương thức thanh toán
                  if (order.paymentMethod != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Thanh toán: ${order.paymentMethod}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Địa chỉ
          if (order.shippingAddress != null || order.billingAddress != null)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.shippingAddress != null) ...[
                      const Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fullAddress(order.shippingAddress),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (order.billingAddress != null) ...[
                      const Text(
                        'Địa chỉ thanh toán',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fullAddress(order.billingAddress),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Danh sách sản phẩm
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sản phẩm',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    // Sửa URL ảnh giống giỏ hàng
                    final fixedImageUrl = ImageUrlHelper.fix(item.imageUrl);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ảnh sản phẩm
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: fixedImageUrl.isNotEmpty
                                  ? Image.network(
                                fixedImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child:
                                  const Icon(Icons.broken_image),
                                ),
                              )
                                  : const Icon(
                                Icons.image_not_supported,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Thông tin sản phẩm
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Format.currency(item.price),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'x${item.quantity} | Tạm tính: ${Format.currency(item.subtotal)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                    if (order.status.toUpperCase() == 'DELIVERED') ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                    onPressed: () async {
                    final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                    builder: (_) => RatingScreen(
                    productId: item.productId,
                    productName: item.productName,
                    ),
                    ),
                    );
                    if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cảm ơn bạn đã đánh giá")),
                    );
                    }
                    },
                    icon: const Icon(Icons.star_border, size: 18, color: Colors.amber),
                    label: const Text(
                    "Đánh giá",
                    style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )
                                )
                               ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
