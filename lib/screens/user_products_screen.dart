import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/screens/edit_product_screen.dart';

import '../providers/products.dart';
import '../widgets/app_drawer.dart';
import '../widgets/user_product_item.dart';

class UserProductsScreen extends StatelessWidget {
  static const routeName = '/user-products';

  Future<void> _refreshProducts(BuildContext context) async {
    await Provider.of<Products>(context, listen: false).fetchProducts(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Products'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed(EditProductScreen.routeName);
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: FutureBuilder(
          future: _refreshProducts(context),
          builder: (ctx, data) {
            if (data.connectionState == ConnectionState.waiting) {
              return Center(child: const CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: () => _refreshProducts(context),
              child: Consumer<Products>(
                builder: (ctx, productsData, _) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    itemCount: productsData.itemsCount,
                    itemBuilder: (_, index) {
                      return Column(
                        children: <Widget>[
                          UserProductItem(
                            id: productsData.items[index].id,
                            title: productsData.items[index].title,
                            imageUrl: productsData.items[index].imageUrl,
                          ),
                          Divider(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          }),
    );
  }
}
