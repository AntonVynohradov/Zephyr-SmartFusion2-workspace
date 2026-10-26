/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * Starter application: proves that the toolchain, the board support and the
 * console work. Blinks led0 once a second and prints a heartbeat on UART0.
 */

#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);

int main(void)
{
	uint32_t count = 0U;

	printk("SmartFusion2 workspace: %s\n", CONFIG_BOARD_TARGET);

	if (!gpio_is_ready_dt(&led) || (gpio_pin_configure_dt(&led, GPIO_OUTPUT_INACTIVE) != 0)) {
		printk("led0 not available\n");
		return 0;
	}

	for (;;) {
		(void)gpio_pin_toggle_dt(&led);
		printk("heartbeat %u\n", count++);
		k_sleep(K_SECONDS(1));
	}

	return 0;
}
