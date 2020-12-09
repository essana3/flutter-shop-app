import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/orders.dart' show Orders;
import '../widgets/app_drawer.dart';
import '../widgets/order_item.dart';

class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders';

  @override
  Widget build(BuildContext context) {
    print('building orders...');
    return Scaffold(
      appBar: AppBar(title: const Text('Your Orders')),
      drawer: AppDrawer(),
      body: FutureBuilder(
        future: Provider.of<Orders>(context, listen: false).fetchOrders(),
        builder: (ctx, data) {
          if (data.connectionState == ConnectionState.waiting) {
            return Center(child: const CircularProgressIndicator());
          }
          if (data.error != null) {
            return Center(child: const Text('An error occurred!'));
          } else {
            return Consumer<Orders>(
              builder: (c, orderData, _) {
                return ListView.builder(
                  itemCount: orderData.ordersCount,
                  itemBuilder: (ctx, index) {
                    return OrderItem(orderData.orders[index]);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
