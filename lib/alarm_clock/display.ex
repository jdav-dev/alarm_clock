defmodule AlarmClock.Display do
  use Agent

  import Bitwise

  alias Circuits.I2C

  @bus_name "i2c-1"
  @address 0x70

  @ht16k33_system_setup 0x20
  @ht16k33_oscillator 0x01

  @setup_data <<@ht16k33_system_setup ||| @ht16k33_oscillator>>

  @ht16k33_blink_cmd 0x80
  @ht16k33_blink_displayon @ht16k33_blink_cmd ||| 0x01
  @ht16k33_blink_off <<@ht16k33_blink_displayon ||| 0x00>>

  @ht16k33_cmd_brightness 0xE0

  @i2c_retries 5

  def start_link(_init_arg) do
    Agent.start_link(
      fn ->
        {:ok, bus} = I2C.open(@bus_name)
        I2C.write!(bus, @address, @setup_data, retries: @i2c_retries)
        show(bus, "", [])
        I2C.write!(bus, @address, @ht16k33_blink_off, retries: @i2c_retries)
        bus
      end,
      name: __MODULE__
    )
  end

  def set_brightness(brightness) when brightness in 0..15 do
    __MODULE__
    |> Agent.get(& &1)
    |> set_brightness(brightness)
  end

  defp set_brightness(bus, brightness) do
    I2C.write!(bus, @address, <<@ht16k33_cmd_brightness ||| brightness>>, retries: @i2c_retries)
  end

  def show(data, opt_or_opts \\ []) do
    opts = List.wrap(opt_or_opts)

    __MODULE__
    |> Agent.get(& &1)
    |> show(data, opts)
  end

  defp show(bus, %{hour: hour} = date_time, opts) do
    opts =
      case rem(hour, 24) do
        hour when hour in 0..11 -> [:am | opts]
        hour when hour in 12..23 -> [:pm | opts]
      end

    date_time
    |> Calendar.strftime("%_I%M")
    |> then(&show(bus, &1, opts))
  end

  defp show(bus, binary, opts) when is_binary(binary) do
    I2C.write!(bus, @address, <<0, encode(binary, opts)::binary>>, retries: @i2c_retries)
  end

  def encode(binary, opts) do
    binary
    |> String.pad_trailing(4)
    |> String.graphemes()
    |> Enum.reduce(<<>>, &encode_grapheme(&1, &2, opts))
  end

  defp encode_grapheme(grapheme, acc, opts) when byte_size(acc) == 4 do
    opts_byte =
      Enum.reduce(opts, 0, fn
        :colon, acc -> acc ||| 0b00000010
        :am, acc -> acc ||| 0b00000100
        :pm, acc -> acc ||| 0b00001000
        :degree, acc -> acc ||| 0b00010000
      end)

    encode_grapheme(grapheme, <<acc::binary, opts_byte, 0>>, opts)
  end

  defp encode_grapheme(grapheme, acc, _opts) do
    <<acc::binary, seven_seg(grapheme), 0>>
  end

  defp seven_seg("0"), do: 0b00111111
  defp seven_seg("1"), do: 0b00000110
  defp seven_seg("2"), do: 0b01011011
  defp seven_seg("3"), do: 0b01001111
  defp seven_seg("4"), do: 0b01100110
  defp seven_seg("5"), do: 0b01101101
  defp seven_seg("6"), do: 0b01111100
  defp seven_seg("7"), do: 0b00000111
  defp seven_seg("8"), do: 0b01111111
  defp seven_seg("9"), do: 0b01100111
  defp seven_seg("A"), do: 0b01110111
  defp seven_seg("b"), do: 0b01111100
  defp seven_seg("C"), do: 0b00111001
  defp seven_seg("c"), do: 0b01011000
  defp seven_seg("d"), do: 0b01011110
  defp seven_seg("E"), do: 0b01111001
  defp seven_seg("F"), do: 0b01110001
  defp seven_seg("G"), do: 0b00111101
  defp seven_seg("H"), do: 0b01110110
  defp seven_seg("h"), do: 0b01110100
  defp seven_seg("I"), do: 0b00110000
  defp seven_seg("i"), do: 0b00000100
  defp seven_seg("J"), do: 0b00001110
  defp seven_seg("L"), do: 0b00111000
  defp seven_seg("n"), do: 0b01010100
  defp seven_seg("O"), do: 0b00111111
  defp seven_seg("o"), do: 0b01011100
  defp seven_seg("P"), do: 0b01110011
  defp seven_seg("q"), do: 0b01100111
  defp seven_seg("r"), do: 0b01010000
  defp seven_seg("S"), do: 0b01101101
  defp seven_seg("t"), do: 0b01111000
  defp seven_seg("U"), do: 0b00111110
  defp seven_seg("u"), do: 0b00011100
  defp seven_seg("y"), do: 0b01101110
  defp seven_seg(" "), do: 0b00000000
  defp seven_seg("_"), do: 0b00001000
  defp seven_seg("-"), do: 0b01000000
  defp seven_seg("‾"), do: 0b00000001
  defp seven_seg("="), do: 0b01001000
  defp seven_seg("≡"), do: 0b01001001
  defp seven_seg("°"), do: 0b01100011
  defp seven_seg("\""), do: 0b00100010
  defp seven_seg("'"), do: 0b00100000
  defp seven_seg("["), do: 0b00111001
  defp seven_seg("("), do: 0b00111001
  defp seven_seg("]"), do: 0b00001111
  defp seven_seg(")"), do: 0b00001111
  defp seven_seg("?"), do: 0b01010011
end
