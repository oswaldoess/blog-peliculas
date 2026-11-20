import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/navegacion.dart';
import '../models/tienda_model.dart';
import '../services/tienda_service.dart';
import '../widgets/estado_vista.dart';
import '../widgets/primary_button.dart';
import 'pago_page.dart';
import 'tienda_page.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final _servicio = TiendaService();
  CarritoModel? _carrito;
  Object? _error;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final c = await _servicio.obtenerCarrito();
      if (!mounted) return;
      setState(() {
        _carrito = c;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _cambiar(CarritoItemModel item, int cantidad) async {
    setState(() => _ocupado = true);
    try {
      final c = cantidad <= 0
          ? await _servicio.quitarDelCarrito(item.producto.id)
          : await _servicio.ponerEnCarrito(item.producto.id, cantidad);
      if (mounted) setState(() => _carrito = c);
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _irAPagar(CarritoModel carrito) async {
    final pagado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => PagoPage(total: carrito.total, piezas: carrito.totalPiezas)),
    );
    if (pagado == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final carrito = _carrito;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi carrito')),
      body: Builder(builder: (context) {
        if (_error != null && carrito == null) return EstadoVista.error(_error!, _cargar);
        if (carrito == null) return const Center(child: CircularProgressIndicator());
        if (carrito.items.isEmpty) {
          return EstadoVista(
            icono: Icons.remove_shopping_cart_outlined,
            titulo: 'Tu carrito está vacío',
            detalle: 'Agrega productos desde la tienda.',
            textoBoton: 'Volver a la tienda',
            alPresionar: () => Navigator.of(context).pop(),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...carrito.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(iconoCategoria(item.producto.categoria), color: AppColors.azul, size: 32),
                    title: Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${formatoPrecio(item.producto.precio)} c/u · ${formatoPrecio(item.subtotal)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: item.cantidad == 1 ? 'Quitar' : 'Uno menos',
                          onPressed: _ocupado ? null : () => _cambiar(item, item.cantidad - 1),
                          icon: Icon(item.cantidad == 1 ? Icons.delete_outline : Icons.remove_circle_outline),
                        ),
                        Text('${item.cantidad}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          tooltip: 'Uno más',
                          onPressed: _ocupado || item.cantidad >= item.producto.stock
                              ? null
                              : () => _cambiar(item, item.cantidad + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            Card(
              color: AppColors.azul.withValues(alpha: 0.08),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Total (${carrito.totalPiezas} piezas)', style: const TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text(
                      formatoPrecio(carrito.total),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.marino),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'PROCEDER AL PAGO',
              onPressed: _ocupado ? null : () => _irAPagar(carrito),
            ),
          ],
        );
      }),
    );
  }
}
