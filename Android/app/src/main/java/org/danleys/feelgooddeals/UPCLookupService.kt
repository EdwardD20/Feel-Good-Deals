package org.danleys.feelgooddeals

import android.annotation.SuppressLint
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

data class UPCItem(
    val ean: String,
    val title: String,
    val description: String?,
    val brand: String?,
    val category: String?,
    val images: List<String>?,
    val offers: List<UPCOffer>
) // UPCItem

data class UPCOffer(
    val merchant: String,
    val domain: String,
    val price: Double?,
    val currency: String,
    val link: String
) {
    val formattedPrice: String?
        @SuppressLint("DefaultLocale")
        get() = price?.let {
            val priceStr = String.format("$%.2f", it)
            if (currency.isEmpty() || currency.equals("USD", ignoreCase = true)) {
                priceStr
            } else {
                "($currency) $priceStr"
            }
        }
} // UPCOffer

class UPCLookupService {
    suspend fun lookupUPC(upc: String): UPCItem = withContext(Dispatchers.IO) {
        val cleanedUPC = upc.trim()
        if (cleanedUPC.isEmpty()) throw IllegalArgumentException("Invalid UPC")

        val urlString = "https://api.upcitemdb.com/prod/trial/lookup?upc=$cleanedUPC"
        Log.d("UPCService", "🔍 $urlString")

        val connection = URL(urlString).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "GET"
            val code = connection.responseCode
            if (code != 200) throw Exception("Error: $code")

            val response = BufferedReader(InputStreamReader(connection.inputStream)).use { it.readText() }
            parseResponse(response)
        } finally {
            connection.disconnect()
        } // try-finally
    } // lookupUPC

    private fun parseResponse(json: String): UPCItem {
        val obj = JSONObject(json)
        val items = obj.getJSONArray("items")
        if (items.length() == 0) throw Exception("No product found")

        val item = items.getJSONObject(0)
        val offers = mutableListOf<UPCOffer>()

        if (item.has("offers") && !item.isNull("offers")) {
            val offersArr = item.getJSONArray("offers")
            for (i in 0 until offersArr.length()) {
                val o = offersArr.getJSONObject(i)
                val price = when {
                    o.isNull("price") -> null
                    o.get("price") is String -> o.getString("price").toDoubleOrNull()
                    else -> o.getDouble("price")
                } // when

                offers.add(UPCOffer(
                    merchant = o.optString("merchant", ""),
                    domain = o.optString("domain", ""),
                    price = price,
                    currency = o.optString("currency", ""),
                    link = o.optString("link", "")
                )) // add
            } // for
        } // if

        // Parse images
        val images = mutableListOf<String>()
        if (item.has("images") && !item.isNull("images")) {
            val imagesArray = item.getJSONArray("images")
            for (i in 0 until imagesArray.length()) {
                images.add(imagesArray.getString(i))
            } // for
        } // if

        return UPCItem(
            ean = item.getString("ean"),
            title = item.getString("title"),
            description = if (item.has("description") && !item.isNull("description")) item.getString("description") else null,
            brand = if (item.has("brand") && !item.isNull("brand")) item.getString("brand") else null,
            category = if (item.has("category") && !item.isNull("category")) item.getString("category") else null,
            images = if (images.isEmpty()) null else images,
            offers = offers
        ) // UPCItem
    } // parseResponse
} // UPCLookupService