package org.danleys.feelgooddeals

import android.util.Log
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)

@Suppress("unused")
@Composable
fun MainScreen() {
    var scannedUPC by remember { mutableStateOf("No UPC set") }
    var productOffers by remember { mutableStateOf<List<UPCOffer>>(emptyList()) }
    var isLoadingProduct by remember { mutableStateOf(false) }
    var lookupError by remember { mutableStateOf<String?>(null) }
    var showScanner by remember { mutableStateOf(false) }
    var webUrl by remember { mutableStateOf<String?>(null) }

    LocalContext.current
    val scope = rememberCoroutineScope()
    val upcService = remember { UPCLookupService() }

    // Costco retailer
    val costcoRetailer = Retailer(
        name = "Costco",
        urlTemplate = "https://www.costco.com/CatalogSearch?dept=All&keyword=<UPC>",
        logoResId = R.drawable.costcologo
    )

    val hasValidSearch = scannedUPC.isNotBlank() && scannedUPC != "No UPC set"

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            ) // TopAppBar
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Logo
            Image(
                painter = painterResource(id = R.drawable.feelgooddealslogo),
                contentDescription = "Feel Good Deals Logo",
                modifier = Modifier
                    .height(120.dp)
                    .padding(bottom = 4.dp)
            ) // Image

            Spacer(modifier = Modifier.height(12.dp))

            // UPC field
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = scannedUPC,
                    onValueChange = { scannedUPC = it },
                    placeholder = { Text("No UPC set") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    shape = RoundedCornerShape(8.dp)
                ) // OutlinedTextField

                if (isLoadingProduct) {
                    Spacer(modifier = Modifier.width(8.dp))
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp)
                    ) // CircularProgressIndicator
                } // if isLoadingProduct
            } // Row

            // Error message
            lookupError?.let { error ->
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = error,
                    color = Color.Red,
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center
                ) // Text
            } // lookupError?.let

            Spacer(modifier = Modifier.height(12.dp))

            // Scan UPC button
            Button(
                onClick = { showScanner = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                    contentColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    painter = painterResource(id = android.R.drawable.ic_menu_camera),
                    contentDescription = "Scan",
                    modifier = Modifier.size(24.dp)
                ) // Icon
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Scan UPC",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                ) // Text
            } // Button

            Spacer(modifier = Modifier.height(12.dp))

            // Offers Table
            if (productOffers.isNotEmpty()) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth(),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(8.dp)
                    ) {
                        Text(
                            text = "Available Offers (${productOffers.size})",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                            modifier = Modifier.padding(8.dp)
                        ) // Text

                        // Table Header
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Merchant",
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                modifier = Modifier.weight(1f)
                            ) // Text
                            Text(
                                text = "Price",
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                modifier = Modifier.width(80.dp),
                                textAlign = TextAlign.End
                            ) // Text
                        } // Row

                        HorizontalDivider()

                        // Table Rows
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            productOffers.forEach { offer ->
                                Card(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable {
                                            webUrl = offer.link
                                        },
                                    colors = CardDefaults.cardColors(
                                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                                    ),
                                    shape = RoundedCornerShape(8.dp)
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(horizontal = 12.dp, vertical = 10.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = offer.merchant,
                                            color = Color.Blue,
                                            textDecoration = TextDecoration.Underline,
                                            fontSize = 16.sp,
                                            modifier = Modifier.weight(1f)
                                        ) // Text

                                        Text(
                                            text = offer.formattedPrice ?: "N/A",
                                            fontSize = 16.sp,
                                            modifier = Modifier.width(80.dp),
                                            textAlign = TextAlign.End
                                        ) // Text
                                    } // Row
                                } // Card
                            } // productOffers.forEach
                        } // Column
                    } // Column
                } // Card

                Spacer(modifier = Modifier.height(12.dp))
            } // if productOffers.isNotEmpty

            // Divider
            HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))

            // Costco button
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = hasValidSearch) {
                        webUrl = costcoRetailer.url(scannedUPC)
                    },
                colors = CardDefaults.cardColors(
                    containerColor = if (hasValidSearch) {
                        MaterialTheme.colorScheme.surfaceVariant
                    } else {
                        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    }
                ),
                shape = RoundedCornerShape(10.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            painter = painterResource(id = costcoRetailer.logoResId),
                            contentDescription = costcoRetailer.name,
                            modifier = Modifier.size(28.dp)
                        ) // Image
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = costcoRetailer.name,
                            fontSize = 16.sp
                        ) // Text
                    } // Row

                    Icon(
                        painter = painterResource(id = android.R.drawable.ic_menu_view),
                        contentDescription = "Open browser"
                    ) // Icon
                } // Row
            } // Card

            Spacer(modifier = Modifier.height(16.dp))
        } // Column
    } // Scaffold

    // Barcode Scanner Dialog
    if (showScanner) {
        BarcodeScannerScreen(
            onDismiss = { showScanner = false },
            onCodeScanned = { code ->
                showScanner = false
                scannedUPC = code
                // Look up product
                scope.launch {
                    isLoadingProduct = true
                    lookupError = null
                    productOffers = emptyList()

                    try {
                        val result = upcService.lookupUPC(code)
                        productOffers = result.offers.sortedBy { it.price }

                        Log.d("MainScreen", "✅ Found ${productOffers.size} offers")
                    } catch (e: Exception) {
                        lookupError = e.message ?: "Unknown error"
                        Log.e("MainScreen", "❌ UPC Lookup Error: ${e.message}")
                    } finally {
                        isLoadingProduct = false
                    } // try-catch-finally
                } // launch
            }
        ) // BarcodeScannerScreen
    } // if showScanner

    // Web View Dialog
    webUrl?.let { url ->
        WebViewDialog(
            url = url,
            onDismiss = { webUrl = null }
        ) // WebViewDialog
    } // webUrl?.let
} // MainScreen

// Retailer data class
data class Retailer(
    val name: String,
    val urlTemplate: String,
    val logoResId: Int
) {
    fun url(upc: String): String {
        val trimmed = upc.trim()
        if (trimmed == "No UPC set" || trimmed.isEmpty()) {
            return ""
        } // if

        return urlTemplate.replace("<UPC>", trimmed)
    } // fun url
} // Retailer